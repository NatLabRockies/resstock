# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import re
import csv
import os
import glob
import logging
from collections import namedtuple, deque

from datetime import datetime
import tarfile


logging.basicConfig(level='INFO')  # Use DEBUG, INFO, or WARNING

KEY_REGEX_MATCH = {
    "stateStart": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Next state will be: '([^']+)'",
    "stateEnd": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Current state: '([^']+)'",
    "measureStart": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Calling (\w+) measure with(?: arguments| no arguments\.)",
    "measureEnd": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] (\w+) runtime: ([\d.]+) seconds",
    "sizingStart": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Started simulation (.*?) at (\d{2}:\d{2}:\d{2}\.\d{3})",
    "sizingEnd": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Finished simulation (.*?) at (\d{2}:\d{2}:\d{2}.\d{3})",
    "workflowItemMeasureStart": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Calling (\w+(?:\.\w+)?) for '(.*?)'",
    "workflowItemMeasureEnd": r"\[(\d{2}:\d{2}:\d{2}\.\d{6}) \w+\] Finished (\w+(?:\.\w+)?) for '(.*?)'",
}

PROFILING_SUMMARY_DIR = "profiling_summary"
STATE_START = namedtuple('stateStart', ['timestamp', 'state'])
STATE_END = namedtuple('stateEnd', ['timestamp', 'state'])
MEASURE_START = namedtuple('measureStart', ['timestamp', 'measure'])
MEASURE_END = namedtuple('measureEnd', ['timestamp', 'measure', 'runtime'])
SIZING_START = namedtuple('sizingStart', ['timestamp', 'sizingRunPath'])
SIZING_END = namedtuple('sizingEnd', ['timestamp'])
WORKFLOW_ITEM_MEASURE_START = namedtuple('workflowItemMeasureStart', [
    'timestamp', 'method', 'workflow'])
WORKFLOW_ITEM_MEASURE_END = namedtuple('workflowItemMeasureEnd', [
    'timestamp', 'method', 'workflow'])

logger = logging.getLogger(__name__)

def main(path):
    """
    main function:
    - read the log file from tar.gz
    - parse the log file and filter out the useful information.
    - generate log summary based on the cleaned nested log.
    """
    logger.info("Analyzing log files from {}".format(path))
    count = 0
    for logpath, log in __extract_running_log(path):
        if count % 100 == 0:
            logger.info("Analyzing log path: {}, which is the {} th log.".format(
                logpath, count))
        count += 1
        infomrationLines = cleanup_oringinal_log(log)

        if not infomrationLines:
            logger.info(">>>>>>> This is Empty >>>>>> ", path, logpath)
            continue

        timeDeltaFromCleanedLog = generate_nest_log_from_namedtuple(infomrationLines)
        timeDeltaFromCleanedLog['logpath'] = logpath
        generatingReport(timeDeltaFromCleanedLog, path)

def aggregate_csv(path):
    """
    After all the csv are generated, aggregate the csvs from each run.
    """
    summaryPath = os.path.join(os.path.dirname(path), PROFILING_SUMMARY_DIR)
    with open(summaryPath + '/' + 'aggregate_profiling.csv', 'w') as fout:
        wout = csv.writer(fout, delimiter=',')
        interesting_files = glob.glob(summaryPath + "/" + "*tar_gz.csv")
        print(interesting_files)
        h = True
        for filename in interesting_files:
            # Open and process file
            logger.info("Aggregating {}".format(filename))
            with open(filename, 'r') as fin:
                if h:
                    h = False
                else:
                    next(fin) # Skip header
                for line in csv.reader(fin):
                    wout.writerow(line)

def __compute_delta(timestamps):
    """
    helper function: calculate the time usage for an action.
    """
    format = "%H:%M:%S.%f"
    return int(abs((datetime.strptime(timestamps[0], format) - datetime.strptime(timestamps[1], format)).total_seconds()))


def __flat_dict_into_list(input, path=None):
    """
    helper function: flat the nested log to easier print into csv.
    input data is a nested log:
    {
    actionA: {subactionB: [timestamp 1, timestamp 2]}
    }
    output data is flatted out
    [actionA, [subactionB, (timestamp 1, timestamp 2)]] for better data handling.
    """
    path = [] if path is None else path
    res = []

    def _flat_dict(inputDict, path: list) -> list:

        if not isinstance(inputDict, dict):
            path.append(inputDict)
            res.append(path[:])
            path.pop()
            return

        for key in inputDict.keys():
            path.append(key)
            _flat_dict(inputDict.get(key), path)
            path.pop()
    _flat_dict(input, path)
    return res


def __create_state_sweepline(nestedLog: dict) -> list:
    """
    helper function: generate [(startName, state start time)] sorted by aceseding.
    Inorder to detect which measure is belong to which state.
    """
    stateStartTime = []
    try:
        for state, (startime, endtime) in nestedLog.get('state', {}).items():
            if state in ['initialization', 'translator', 'ep_measures', 'simulation', 'postprocess']:
                continue
            else:
                stateStartTime.append(
                    (state, datetime.strptime(startime, "%H:%M:%S.%f")))
        stateStartTime.sort(key=lambda x: x[1], reverse=True)
    except Exception as ex:
        logger.info(ex.__class__.__name__ + " under " + "create_state_sweepline")
        logger.info(nestedLog.get('state'))
    return stateStartTime


def __get_state_from_workflow_measure(timestamp: list, stateSweepLine: list):
    """
    Pass a measure's timestamps of start and end, return state its belong to.
    Since the state sweepline is sorted, we just need do it in one pass.
    """
    WorkFlowstarttime = datetime.strptime(timestamp[0], "%H:%M:%S.%f")
    for state, starttime in stateSweepLine:
        if WorkFlowstarttime > starttime:
            return state
    return None


def __uniform_sizing_json(nestedLog: dict):
    """
    uniform sizing log with other logs. Since sizing log has no sizing name mention in the end logging at beginning.
    """
    sizingDict = nestedLog.get('sizing', [])
    newSizingDict = {}

    for sizingPath, starttime, endTime in sizingDict:
        newSizingDict[sizingPath] = [starttime, endTime]
    nestedLog['sizing'] = newSizingDict


def __is_sizing_included(sizingTimeStamps: tuple, workflowStartTime: str, workflowEndTime: str) -> bool:
    """
    Detect whether a sizing is included in a workflow step.
    """
    format = "%H:%M:%S.%f"
    return datetime.strptime(sizingTimeStamps[0], format) > datetime.strptime(workflowStartTime, format) and datetime.strptime(sizingTimeStamps[1], format) < datetime.strptime(workflowEndTime, format)




def __create_workflow_measure_sweepLine(workflowFromNestedLog: dict) -> list:
    """
    helper function: use workflow information from nested log to created a sorted timestamp list of workflow
    in order to detect the inclusion of workflow and measure step.
    """
    workFlowMeasures = []
    for state, var in workflowFromNestedLog.items():
        for idx, timestamp in enumerate(var):
            if idx % 2 == 0:
                try:
                    workFlowMeasures.append(
                        (state, datetime.strptime(timestamp, "%H:%M:%S.%f")))
                except Exception:
                    logger.info("work flow create sweepline error")
                    logger.info(timestamp)

    workFlowMeasures.sort(key=lambda x: x[1], reverse=True)
    return workFlowMeasures


def __filted_sizing_name(sizingPath: str) -> str:
    """
    helper function:
    Change sizing name from /var/simdata/openstudio/run/000_BuildExistingModel/set_hvac_template_SR to set_hvac_template_SR
    for better indication.
    """
    return '_'.join([st for st in sizingPath.split('/')[-1].split('_') if ('SR') not in st])


def __extract_running_log(tar_path):
    """
    helper function: find the singularity_output.log from tar.gz.
    """
    with tarfile.open(tar_path, 'r') as t:
        for member in t.getmembers():

            if "singularity_output.log" in member.name:
                logfile = t.extractfile(member).readlines()
                yield (member.name, logfile)

def cleanup_oringinal_log(originalLog):
    """
    Parsing the log lines and generate the nested log.
    for example:
    [timestamp A] action A start.
    [timestamp B] action A finished.
    Should be parsed into a namedtuple with actionname, action start time, action end time like
    (action name: action A, action start time: timestamp A, action end time: timestamp B)
    """
    res = []
    for line in originalLog:
        line = line.decode()
        for k, match in KEY_REGEX_MATCH.items():
            currentMatch = re.search(match, line)
            if not currentMatch:
                continue

            if "stateStart" == k:
                res.append(STATE_START(
                    currentMatch.group(1), currentMatch.group(2).lower()))

            if "stateEnd" == k:
                res.append(
                    STATE_END(currentMatch.group(1), currentMatch.group(2).lower()))

            if "measureStart" == k:
                res.append(MEASURE_START(
                    currentMatch.group(1), currentMatch.group(2).lower()))

            if "measureEnd" == k:
                res.append(MEASURE_END(currentMatch.group(
                    1), currentMatch.group(2).lower(), currentMatch.group(3).lower()))

            # TODO: fixing the data structure of sizing, since the log comes with sizing detail.
            if "sizingStart" == k:
                sizingPath = currentMatch.group(2)
                res.append(SIZING_START(currentMatch.group(
                    3), __filted_sizing_name(sizingPath)))

            if "sizingEnd" == k:
                res.append(SIZING_END(currentMatch.group(3)))

            if "workflowItemMeasureStart" == k:
                res.append(WORKFLOW_ITEM_MEASURE_START(
                    currentMatch.group(1), currentMatch.group(2).lower(),
                    currentMatch.group(3).lower()))

            if "workflowItemMeasureEnd" == k:
                res.append(WORKFLOW_ITEM_MEASURE_END(
                    currentMatch.group(1),
                    currentMatch.group(2).lower(),
                    currentMatch.group(3).lower()))
    return res


def generate_nest_log_from_namedtuple(cleanedLog: list):
    """
    Convert nametuple data into nested dictionary for further cleanup.
    """
    queue = deque(cleanedLog)
    startLog = queue.popleft()
    endLog = queue.pop()

    result = {'state': {}, 'measure': {}, 'sizing': [], 'workflowmeasure': {}}

    for item in queue:
        if type(item) is STATE_START:
            if not result['state'].get(item.state):
                result['state'][item.state] = []
            result['state'][item.state].append(item.timestamp)

        if type(item) is STATE_END:
            if not result['state'].get(item.state):
                result['state'][item.state] = []
            result['state'][item.state].append(item.timestamp)

        if type(item) is MEASURE_START:
            if not result['measure'].get(item.measure):
                result['measure'][item.measure] = []
            result['measure'][item.measure].append(item.timestamp)

        if type(item) is MEASURE_END:

            # Hacky bypass.
            # TODO: fix the logic to publish the logging.
            if item.measure == "setnistinfiltrationcorrelations":
                item = item._replace(
                    measure="set_nist_infiltration_correlations")

            if not result['measure'].get(item.measure):
                result['measure'][item.measure] = []
            result['measure'][item.measure].append(item.timestamp)

        # since sizing log end doesnt comes with any key word for the sizing file
        # we could use the last sizing start timestamp as best bet.
        if type(item) is SIZING_START:
            result['sizing'].append([item.sizingRunPath, item.timestamp])

        if type(item) is SIZING_END:
            if result['sizing']:
                result['sizing'][-1].append(item.timestamp)

        if type(item) is WORKFLOW_ITEM_MEASURE_START:
            if not result['workflowmeasure'].get(item.workflow + '.'+item.method):
                result['workflowmeasure'][item.workflow + '.' + item.method] = []
            result['workflowmeasure'][item.workflow +
                                      "."+item.method].append(item.timestamp)

        if type(item) is WORKFLOW_ITEM_MEASURE_END:
            if not result['workflowmeasure'].get(item.workflow+"."+item.method):
                result['workflowmeasure'][item.workflow + "." + item.method] = []
            result['workflowmeasure'][item.workflow + "." + item.method].append(
                item.timestamp)

    result['total'] = [startLog.timestamp, endLog.timestamp]
    return result

def generatingReport(nestedLog: dict, path: str):
    """
    After nested log is generated, read the nested log and generate csv file.
    """
    __uniform_sizing_json(nestedLog)
    logpath = nestedLog.get('logpath')
    upgrade_id = logpath.split("/")[1]
    building_id = logpath.split('/')[2].replace('bldg', '')[-4:]

    del nestedLog['logpath']

    totalTime = __compute_delta(nestedLog.get('total'))
    del nestedLog['total']

    field_names = ['building_id', 'upgrade_id',
                   'type', 'workflow_state', 'workflow_substate',
                   'measure_name', 'measure_state', 'time']

    workFlowMeasureSweepLine = __create_workflow_measure_sweepLine(
        nestedLog.get("workflowmeasure", {}))
    stateStartTime = __create_state_sweepline(nestedLog=nestedLog)
    sizingDetail = nestedLog.get('sizing', {})

    summaryPath = os.path.join(os.path.dirname(path), "profiling_summary")
    if not os.path.exists(summaryPath):
        os.makedirs(summaryPath)

    path = path.replace('.', '_').replace('/', '_').replace('tar.gz', "")
    summaryFullPath = summaryPath + "/" + "reporting_{}.csv".format(path)
    with open(summaryFullPath, mode='a', newline="") as file:
        writer = csv.DictWriter(file, fieldnames=field_names)
        if not file.tell():
            writer.writeheader()
        writer.writerow({
            'upgrade_id': upgrade_id,
            'building_id': building_id,
            'type': 'total',
            'workflow_state': 'total',
            'workflow_substate': 'total',
            'measure_name': 'total',
            'measure_state': 'total',
            'time': totalTime
        })

        seen = set()
        for majorType, *vals in __flat_dict_into_list(nestedLog):
            datrum = {}
            if majorType != 'sizing' and len(vals[1]) % 2 != 0:
                datrum = {
                    'upgrade_id': upgrade_id,
                    'building_id': building_id,
                    'type': 'detail',
                    'workflow_state': "ERROR",
                    'workflow_substate': "ERROR",
                    'measure_name': "ERROR",
                    'measure_state': "ERROR",
                    'time': "ERROR"
                }
                writer.writerow(datrum)
                continue

            if majorType == 'state':
                state, time = vals[0], __compute_delta(vals[1])
                if state in ['initialization', 'translator', 'ep_measures', 'simulation', 'postprocess']:
                    datrum = {
                        'upgrade_id': upgrade_id,
                        'building_id': building_id,
                        'type': 'detail',
                        'workflow_state': state,
                        'workflow_substate': state,
                        'measure_name': state,
                        'measure_state': state,
                        'time': time
                    }
                    writer.writerow(datrum)

            if majorType == 'workflowmeasure':
                for k in range(len(vals[1])//2):
                    measureStartTime, measureEndTime = vals[1][2 *
                                                               k], vals[1][2 * k + 1]
                    state, time = __get_state_from_workflow_measure(
                        (measureStartTime, measureEndTime), stateStartTime), __compute_delta((measureStartTime, measureEndTime))
                    measureName = vals[0].split('.')[0]
                    workflowSubState = '.'.join(vals[0].split('.')[-2:])
                    measureState = vals[0].split('.')[-1]
                    sizingTime = 0

                    for sizingPath, sizingTimeStamp in sizingDetail.items():

                        if __is_sizing_included(sizingTimeStamp, measureStartTime, measureEndTime):
                            datrum = {
                                'upgrade_id': upgrade_id,
                                'building_id': building_id,
                                'type': 'detail',
                                'workflow_state': state,
                                'workflow_substate': workflowSubState,
                                'measure_name': measureName + "." + sizingPath,
                                'measure_state': "sizing",
                                'time': __compute_delta(sizingTimeStamp)
                            }
                            sizingTime += __compute_delta(sizingTimeStamp)
                            seen.add(sizingPath)
                            writer.writerow(datrum)

                    # workflow measure
                    datrum = {}
                    datrum = {
                        'upgrade_id': upgrade_id,
                        'building_id': building_id,
                        'type': 'detail',
                        'workflow_state': state,
                        'workflow_substate': workflowSubState,
                        'measure_name': measureName,
                        'measure_state': measureState,
                        'time': time
                    }
                    if ("." not in measureName) and (measureName == "buildexistingmodel") and (workflowSubState == "measure.run") and (measureState == "run"):
                        continue
                    writer.writerow(datrum)

            elif majorType == 'measure':
                starttime, endtime = vals[1]
                measure_name, time = vals[0], __compute_delta(
                    (starttime, endtime))
                measure_starttime = datetime.strptime(
                    vals[1][0], "%H:%M:%S.%f")
                for (workflow_measure, workflow_measure_starttime) in workFlowMeasureSweepLine:
                    if measure_starttime > workflow_measure_starttime:
                        father_workflow_measure = workflow_measure
                        break
                workflow_state = __get_state_from_workflow_measure(
                    (starttime, endtime), stateStartTime)

                sizingTime = 0
                for sizingPath, sizingTimeStamp in sizingDetail.items():
                    if __is_sizing_included(sizingTimeStamp, starttime, endtime):
                        sizingTime += __compute_delta(sizingTimeStamp)

                datrum = {
                    'upgrade_id': upgrade_id,
                    'building_id': building_id,
                    'type': 'detail',
                    'workflow_state': workflow_state,
                    'workflow_substate': '.'.join(father_workflow_measure.split('.')[1:]),
                    'measure_name': father_workflow_measure.split('.')[0] + '.'+measure_name,
                    'measure_state': father_workflow_measure.split('.')[-1],
                    'time': time - sizingTime
                }

                writer.writerow(datrum)