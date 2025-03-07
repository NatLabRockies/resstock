# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import glob
import io
import os
from os import path
import re
import subprocess
from sys import platform
from .profiling import profilingPerformance
import tarfile
import yaml
import zipfile
import shutil
import gzip

# from dask.distributed import Client
from joblib import Parallel, delayed, parallel_backend
import numpy as np
import pandas as pd

def extract_models_from_simulation_output(yml_path, up_id='up00', output_vars=[]):
    """Extract individual models from a ComStock run for detailed debugging

    This function extracts the in.idf, in.osm, eplustbl.htm, and run.log for each of the requested
    building IDs to the my_run/results/simulation_outputs/model_files directory.
    building IDs must be specified in my_run/building_id_list.csv, column header = building_id
    This method can optionally also add output variables to the extracted IDF files
    to enable more detailed debugging.

    :param yml_path: The path to the YML file used to run buildstockbatch
    :param up_id: A string describing the desired upgrade to extract
    :param output_vars: A list of output variables to add to the IDFs. These will be added
        using the *, so all available instances of this variable will be requested at the Timstep frequency.

    :return: None
    """
    # Check that this is running on HPC, won't work locally
    if not(platform == "linux" or platform == "linux2"):
        raise RuntimeError('extract_models_from_simulation_output only works on HPC')

    # Inputs from project yml file
    with open(yml_path) as proj_yml:
        yml = yaml.load(proj_yml, Loader=yaml.FullLoader)
        output_dir = os.path.normpath(yml['output_directory'])
        simulation_output_dir = os.path.join(output_dir, 'results', 'simulation_output')
        results_csv_path = os.path.join(output_dir, 'results', 'results_csvs')
        weather_file_dir = yml['weather_files_path']
        path_to_buildstock_file = yml['sampler']['args']['sample_file']
        username = os.environ.get('LOGNAME')
        project_name = os.path.basename(output_dir)

    # Make directory to extract the models into
    model_files_dir = os.path.join(simulation_output_dir, 'model_files')
    if not path.exists(model_files_dir):
            os.makedirs(model_files_dir)

    # Load building_id_list.csv
    building_id_list_path = os.path.join(output_dir, 'building_id_list.csv')
    if not path.exists(building_id_list_path):
        raise FileNotFoundError(f'Create a CSV of building IDs here: {building_id_list_path}')
    df_building_id = pd.read_csv(building_id_list_path)

    # Load buildstock.csv
    headers = pd.read_csv(path_to_buildstock_file, nrows=0).columns.tolist()
    if 'sample_building_id' in headers:
        i = 'sample_building_id'  # Older ComStock versions
    elif 'Building' in headers:
        i = 'Building'  # Newer ComStock versions
    df_bstock_csv = pd.read_csv(path_to_buildstock_file, index_col=i)

    # Load results.csv
    path_to_zipped_results_file = os.path.join(results_csv_path, f'results_{up_id}.csv.gz')
    df_results_csv = pd.read_csv(path_to_zipped_results_file, compression='infer', header=0, sep=',', quotechar='"', index_col='building_id')

    if up_id != "up00":
        # load baseline results.csv
        path_to_baseline_results_file = os.path.join(results_csv_path, 'results_up00.csv.gz')
        baseline_results_csv = pd.read_csv(path_to_baseline_results_file, compression='infer', header=0, sep=',', quotechar='"', index_col='building_id')

    # Untar all relevant models in a single job's .tar.gz and pull required zip files into folder structure (.idf, .osm)
    def model_extract(tar_path, tar_to_zip_dict, tar_to_id_dict, bldgid_to_zip_dict, model_files_dir):
        zip_list = tar_to_zip_dict[tar_path]
        job_id = tar_path.split('_')[-1].split('.')[0].replace('job', '')

        # make a scratch directory including username, project name, and jobid to untar files into
        scratch_untar_dir = os.path.join('/tmp/scratch', username, project_name, job_id)
        print(f"untarring job_{job_id} for the following zips: {zip_list}")
        if not os.path.isdir(scratch_untar_dir):
            os.makedirs(scratch_untar_dir)

        # join zip list into single string
        zip_str = ' '.join(zip_list)  # should be 'bldg0000012/run/datapoint.zip bldg0000013/run/datapoint.zip' etc. etc

        # untar files to scratch directory
        untar_command = f'date && time tar -xvzf {tar_path} --no-anchored {zip_str} && date'
        #untar_command = f'date && time tar --use-compress-program=pigz -xf {tar_path} --no-anchored {zip_str} && date'
        res = subprocess.run(untar_command, cwd=scratch_untar_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        if res.returncode != 0:
            print(f"Error in untar command `{untar_command}`: {res.stderr}")

        outcome = list()

        # Loop through building IDs found in current tar file
        for building_id in tar_to_id_dict[tar_path]:
            path_to_datapoint = bldgid_to_zip_dict[building_id]

            # path to zip file name
            from_dir = os.path.join(scratch_untar_dir, os.path.normpath(path_to_datapoint))

            # get and store file metadata as variables
            bldg_id = building_id
            bldg_id_full = '{0}'.format(str(bldg_id).zfill(7))
            bldg_type = (df_bstock_csv.loc[df_bstock_csv.index == bldg_id, 'building_type']).iat[0]
            job_id = (df_results_csv.loc[df_results_csv.index == bldg_id, 'job_id']).iat[0]

            # create directory for this model
            model_dir = os.path.join(model_files_dir, f"{bldg_type}_BLDG{bldg_id_full}_JOB{job_id}_{up_id}")
            if not path.exists(model_dir):
                os.makedirs(model_dir)

            # get full building id
            building = 'bldg{:07d}'.format(building_id)

            # unzip files and drop relvant ones in desired locations
            attempt_count = 1
            failure = {'type': False}
            while attempt_count <= 5:
                try:
                    attempt_count += 1
                    zf = zipfile.ZipFile(os.path.join(from_dir))
                    files_to_extract = ['in.idf', 'in.osm', 'eplustbl.htm', 'run.log']
                    for file_to_extract in files_to_extract:
                        with open(os.path.join(model_dir, file_to_extract), 'wb') as f:
                            f.write(zf.read(file_to_extract))
                    zf.close()
                except KeyError as err:
                    failure = {
                        'type': 'extraction failure', 'instance': building, 'subtype': 'file not found in zip', 'details': str(err)
                    }
                except zipfile.BadZipFile as err:
                    failure = {
                        'type': 'extraction failure', 'instance': building, 'subtype': 'bad zip', 'details': str(err)
                    }
                except Exception as err:
                    failure = {
                        'type': 'extraction failure', 'instance': building, 'subtype': 'other',
                        'details': str(err)
                    }
            if not failure['type'] == False:
                outcome.append(failure)

        results = pd.DataFrame(outcome)

        return results


    # Find failed runs as to not include those
    no_result_runs = list(df_results_csv.loc[df_results_csv['completed_status'] != 'Success'].index)
    df_building_id = df_building_id.loc[~df_building_id['building_id'].isin(no_result_runs)]

    # Loop through user-input building ids for extraction, create dictionaries
    tar_dict = {}
    tar_file_bldgid_dict = {}
    zip_list_bldgid_dict = {}
    bldgid_to_zip_dict = {}
    for index, row in df_building_id.iterrows():
        # get and store file metadata
        bldg_id = row['building_id']
        bldg_id_full = '{0}'.format(str(row['building_id']).zfill(7))
        bldg_type = (df_bstock_csv.loc[df_bstock_csv.index == bldg_id, 'building_type']).iat[0]
        job_id = (df_results_csv.loc[df_results_csv.index == bldg_id, 'job_id']).iat[0]

        # create directory to save files if one does not exist - save path as variable for later use
        model_folder_name = os.path.join(f"model_files/{bldg_type}_BLDG{bldg_id_full}_JOB{job_id}_{up_id}")

        # name of file to extract - job ID will be variable, but rest should be constant
        tar_member = f"./{up_id}/bldg{bldg_id_full}/run/data_point.zip"

        # tar file path
        tar_path_full = os.path.join(simulation_output_dir, f"simulations_job{job_id}.tar.gz")

        tar_file_bldgid_dict[bldg_id] = tar_path_full
        zip_list_bldgid_dict[f"./{up_id}/bldg{bldg_id_full}/run/data_point.zip"] = tar_path_full
        bldgid_to_zip_dict[bldg_id] = f"./{up_id}/bldg{bldg_id_full}/run/data_point.zip"

        # input file name for extraction
        tar_dict[bldg_id] = [bldg_id_full, bldg_type, job_id, model_folder_name, tar_member]

    # Create dictionary with tar files to extract as the keys, lists of building ids as the values
    tar_to_id_dict = {}
    for i in list(set(tar_file_bldgid_dict.values())):
        bldgs = []
        for key, value in tar_file_bldgid_dict.items():
            if tar_file_bldgid_dict[key] == i:
                bldgs.append(key)
        tar_to_id_dict[i] = bldgs

    # Create dictionary with tar files to extract as the keys, lists of zip file names as the values
    tar_to_zip_dict = {}
    for i in list(set(zip_list_bldgid_dict.values())):
        bldgs = []
        for key, value in zip_list_bldgid_dict.items():
            if zip_list_bldgid_dict[key] == i:
                bldgs.append(key)
        tar_to_zip_dict[i] = bldgs

    # Untar all jobs in parallel
    tar_paths = list(tar_to_zip_dict.keys())
    print(f'untarring {tar_paths}')
    Parallel(n_jobs=-1, verbose=10) (delayed(model_extract)(tar_path, tar_to_zip_dict, tar_to_id_dict, bldgid_to_zip_dict, model_files_dir) for tar_path in tar_paths)
    # Uncomment to run in series for debugging
    # for tar_path in tar_paths:
    #     model_extract(tar_path, tar_to_zip_dict, tar_to_id_dict, bldgid_to_zip_dict, model_files_dir)

    # Get the weather file for each model
    for subdirs, dirs, files in os.walk(model_files_dir):
        for directory in dirs:
            bldg_id = int(directory.split('_')[-3].replace('BLDG', '').lstrip('0'))
            if up_id == 'up00':
                epw_name = list(df_results_csv.loc[df_results_csv.index==bldg_id, 'build_existing_model.changebuildinglocation_weather_file_name'])[0]
            else:
                # look for epw name in baseline results csv
                epw_name = list(baseline_results_csv.loc[baseline_results_csv.index==bldg_id, 'build_existing_model.changebuildinglocation_weather_file_name'])[0]
            epw_zip = zipfile.ZipFile(weather_file_dir)
            model_dir = os.path.join(model_files_dir, directory)
            epw = epw_zip.extract(epw_name, path=model_dir)

            # rename file to in.epw, delete if already exists
            epw_path = os.path.join(model_dir, 'in.epw')
            if os.path.isfile(epw_path):
                os.unlink(epw_path)
                os.rename(epw, epw_path)
                continue
            else:
                os.rename(epw, epw_path)

    # Add new output variables to each IDF
    for idf_path in glob.glob(f'{model_files_dir}/**/in.idf'):
        with open(idf_path, 'a+') as file_object:
            for out_var in output_vars:
                # move curser to start of file
                file_object.seek(0)
                if isinstance(out_var, list):
                    # [var name, key value, reporting frequency]
                    # Append text at the end of file
                    file_object.write("Output:Variable,\n")
                    # key value
                    if not out_var[1].strip():
                        # empty key value
                        file_object.write("  *,                                      !- Key Value\n")
                    else:
                        offset = 39 - len(out_var[1]) if len(out_var[1]) <= 38 else 1
                        file_object.write(f"  {out_var[1]},{offset*' '}!- Key Value\n")
                    # make spacing consistent with rest of IDF
                    offset = 39 - len(out_var[0]) if len(out_var[0]) <= 38 else 1
                    file_object.write(f"  {out_var[0]},{offset*' '}!- Variable Name\n")
                    # reporting frequency
                    if not out_var[2].strip():
                        # empty frequency, default to timestep
                        file_object.write("  timestep;                               !- Reporting Frequency\n\n")
                    else:
                        offset = 39 - len(out_var[2]) if len(out_var[2]) <= 38 else 1
                        file_object.write(f"  {out_var[2]};{offset*' '}!- Reporting Frequency\n\n")
                else:
                    # Append text at the end of file
                    file_object.write("Output:Variable,\n")
                    file_object.write("  *,                                      !- Key Value\n")
                    # make spacing consistent with rest of IDF
                    if len(out_var) <= 38:
                        offset = 39 - len(out_var)
                    else:
                        offset = 1
                    file_object.write(f"  {out_var},{offset*' '}!- Variable Name\n")
                    file_object.write("  timestep;                               !- Reporting Frequency\n\n")

def run_extracted_models(yml_path, energyplus_version='22.1.0'):
    """Run previously-extracted individual models from a ComStock run for detailed debugging

    This function runs all in.idf files in the my_run/results/simulation_output/model_files directory.

    :param yml_path: The path to the YML file used to run buildstockbatch
    :param energyplus_version: A string with the EnergyPlus version to use.
        Executables are assumed to be in /lustre/vast/shared-projects/EnergyPlus

    :return: None
    """
    if not(platform == "linux" or platform == "linux2"):
        raise RuntimeError('extract_models_from_simulation_output only works on HPC')

    # Inputs from project yml file
    with open(yml_path) as proj_yml:
        yml = yaml.load(proj_yml, Loader=yaml.FullLoader)
        output_dir = os.path.normpath(yml['output_directory'])
        model_files_dir = os.path.join(output_dir, 'results', 'simulation_output', 'model_files')

    # Check requested EnergyPlus executable
    energyplus_exe_path = f'/lustre/vast/shared-projects/EnergyPlus/v{energyplus_version}/build/Products/energyplus-{energyplus_version}'
    if not os.path.exists(energyplus_exe_path):
        raise FileNotFoundError(f"Could not find {energyplus_exe_path}, check for appropriate energyplus_version")
    print(f'Using EnergyPlus from: {energyplus_exe_path}')

    # Run a single model
    def run_idf(idf_path, energyplus_exe_path):
        idf_dir = os.path.dirname(idf_path)
        run_command = f'{energyplus_exe_path} -w in.epw -r  in.idf'
        # run_command = f'{energyplus_exe_path} -w {idf_dir}/in.epw -r  {idf_dir}/in.idf'
        if not os.path.exists(idf_path):
            print
            raise FileNotFoundError(f'Did not find IDF at: {idf_path}')
        # res = subprocess.run(run_command, cwd=idf_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        res = subprocess.run(run_command, cwd=idf_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        if res.returncode != 0:
            std_out = res.stdout.decode().split('\n')
            print(f"Error running IDF command `{run_command}`: {std_out[-4:]}")
            # exit(1)

    # Run models in parallel
    idf_paths = glob.glob(f'{model_files_dir}/**/in.idf')
    print(f'Running {len(idf_paths)} IDF files')
    # Uncomment to run in series for debugging
    # for idf_path in idf_paths:
    #     run_idf(idf_path, energyplus_exe_path)
    Parallel(n_jobs=-1, verbose=10) (delayed(run_idf)(idf_path, energyplus_exe_path) for idf_path in idf_paths)

def get_simulation_output_dir_from_yml(yml_path):
    """Gets the simulation output directory from the YML file

    :param yml_path: The path to the YML file used to run buildstockbatch

    :return: String of the simulation output directory path
    """
    try:
        with open(yml_path) as f:
            yml = yaml.load(f, Loader=yaml.SafeLoader)
    except FileNotFoundError as err:
        raise err

    output_dir = yml['output_directory'].rstrip('/')
    sim_out_dir = os.path.join(output_dir, 'results', 'simulation_output')
    if not os.path.exists(sim_out_dir):
        raise RuntimeError(f'Simulation outputs not found at {sim_out_dir}, check buildstockbatch progress or ouputs')

    return sim_out_dir

def extract_energyplus_error_files_from_jobs(yml_path):
    """Extract the contents from all eplusout.err files in a simulations_job*.tar.gz to a single file

    This function looks inside the .tar.gz, finds the data_point.zip files, gets the eplusout.err files,
    and concatenates these to a single large job*_eplusout.err file for each job.
    This file can be used to determine common warnings/errors and to find models that exhibit them.

    :param yml_path: The path to the YML file used to run buildstockbatch

    :return: None
    """
    simulation_output_dir = get_simulation_output_dir_from_yml(yml_path)
    errs_dir = os.path.join(simulation_output_dir, 'eplusout_errors')
    if not path.exists(errs_dir):
        os.makedirs(errs_dir)
    for tar_path in glob.glob(f'{simulation_output_dir}/simulations_job*.tar.gz'):
        job_id = re.search(r'.*simulations_job(\d+).tar.gz', tar_path).group(1)
        job_errs_name = f'job{job_id}_eplusout.err'
        job_errs_path = os.path.join(errs_dir, job_errs_name)
        if os.path.exists(job_errs_path):
            print(f'Already extracted errors from job {job_id} to {job_errs_path}')
            continue
        print(f'Extracting errors from job {job_id} to {job_errs_path}')
        with open(job_errs_path, 'w') as job_errs:
            with tarfile.open(tar_path) as tar:
                zip_count = 0
                for tar_member in tar.getmembers():
                    if not 'data_point.zip' in tar_member.name:
                        continue
                    bldg_id = re.search(r'.*bldg(\d+).*', tar_member.name).group(1)
                    bldg_id = int(bldg_id)
                    zip_count += 1
                    # print(f'reading zip #{zip_count}: {tar_member.name}')
                    datapoint_zip_bytes=tar.extractfile(tar_member).read()
                    with zipfile.ZipFile(io.BytesIO(datapoint_zip_bytes)) as zip:
                        try:
                            errs = zip.read("eplusout.err").decode()
                            job_errs.write(f'eplusout.err from building_id={bldg_id}\n')
                            job_errs.write(errs)
                        except KeyError as err:
                            print(f'Did not find eplusout.err in data_point.zip for building {bldg_id}')
                tar.close()

def generalize_energyplus_error_message(w):
    """Generalize warning/error messages to replace specific object names and timestamps with .*

    This function strips model-specific contents from warning/error messages so they can be grouped.

    :param w: A single warning or error from an eplusout.err file

    :return: A string warning/error message with the specific object names replaced with .*
    """
    t = "TYPICAL"
    w = str.replace(w, '"', "'")  # All quotes inside strings to single quotes for easier coding
    w = str.replace(w, '*', "")  # All quotes inside strings to single quotes for easier coding
    w = str.replace(w, '** Warning ** ', "")
    w = w.strip()

    # Find the number of recurrences
    m = re.search(r'This error occurred (\d+) total times', w)
    if m:
        n = int(m.group(1))
        pre_continuation = re.search(r"(.*)This error occurred.*", w).group(1)
        w = re.sub(r".*This error occurred.*", pre_continuation, w).strip()
    else:
        n = 1

    # These regexes are used to find common errors and generalize them so they can be counted
    warn_regexs = [
        # Schedules
        r"ProcessScheduleInput: DecodeHHMMField, Invalid 'until' field value is not a multiple of the minutes for each timestep: .* Other errors may result. Occurred in Day Schedule=.*",
        r"Schedule:Day:Interval='.*', Blank Schedule Type Limits Name",
        r"Schedule:Constant='.*', Blank Schedule Type Limits Name",
        r"ProcessScheduleInput: Schedule:Year='.*', Blank Schedule Type Limits Name input -- will not be validated.",
        r"ProcessScheduleInput: Schedule:Day:Interval='.*', , One or more values are not integer as required by Schedule Type Limits Name=ONOFF",
        r"Fan:ZoneExhaust='.*' has fractional values in Schedule=.*. Only 0.0 in the schedule value turns the fan off.",
        r"Standard Time Meridian and Time Zone differ by more than 1, Difference='.*' Solar Positions may be incorrect",

        # Outputs
        r"Output:Meter: invalid Key Name='.*' - not found",
        r"Output:Meter:MeterFileOnly: invalid Key Name='.*' - not found.",
        r"In Output:Table:Monthly '.*' invalid Variable or Meter Name '.*'",
        r"The resource referenced by LifeCycleCost:UsePriceEscalation= '.*' has no energy cost.  .*",
        r"Output:Meter:MeterFileOnly requested for '.*' \(TimeStep\), already on 'Output:Meter'. Will report to both eplusout.eso and eplusout.mtr",
        r"The following Report Variables were requested but not generated -- check.rdd file.*",
        r"Processing Monthly Tabular Reports: Variable names not valid for this simulation.*",

        # Coils
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed '.*' - Full load outlet air dry-bulb temperature < 2C. This indicates the possibility of coil frost/freeze. .*",
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed '.*' - Air-cooled condenser inlet dry-bulb temperature below 0 C. .*",
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed='.*':  Energy Input Ratio Modifier curve \(function of temperature\) output is negative.*",
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed='.*' - Air volume flow rate per watt of rated total cooling capacity is out of range.*",
        r"Coil:Cooling:DX:VariableRefrigerantFlow '.*' - Air volume flow rate per watt of rated total cooling capacity is out of range.*",
        r"GetDXCoils: Coil:Cooling:DX:SingleSpeed='.*', invalid ...Part Load Fraction Correlation Curve Name = .* has out of range value. .*",
        r"For object = Coil:Cooling:DX:SingleSpeed, name = '.*' Calculated outlet air relative humidity greater than 1..*",
        r"For object = Coil:Cooling:DX:TwoSpeed, name = '.*' Calculated outlet air relative humidity greater than 1..*",
        r"For object = Coil:Cooling:DX:VariableRefrigerantFlow, name = '.*' Calculated outlet air relative humidity greater than 1..*",
        r"GetDXCoils: Coil:Heating:DX:SingleSpeed='.*', invalid ...Part Load Fraction Correlation Curve Name = .* has out of range value. .*",
        r"GetDXCoils: Coil:Heating:DX:SingleSpeed='.*' curve values ... Defrost Energy Input Ratio Function of Temperature Curve Name = .* output is not equal to 1.0.*",
        r"GetDXCoils: Coil:Heating:DX:SingleSpeed='.*' curve values ... Energy Input Ratio Function of Temperature Curve Name = .* output is not equal to 1.0.*",
        r"GetDXCoils: Coil:Cooling:DX:TwoSpeed='.*', invalid ...Part Load Fraction Correlation Curve Name = .* has out of range value. .*",
        r"Coil:Heating:DX:SingleSpeed '.*' - Air volume flow rate per watt of rated total heating capacity is out of range .*",
        r"CalcTwoSpeedDXCoilStandardRating: Did not find an appropriate fan associated with DX coil named = '.*'. Standard Ratings will not be calculated.",
        r"Coil control failed to converge for .*   Iteration limit exceeded in calculating system sensible part-load ratio..*",
        r"SizeWaterCoil: Coil='.*', Cooling Coil has leaving humidity ratio > entering humidity ratio..*",
        r"Coil control failed for AirLoopHVAC:UnitarySystem:.*   sensible part-load ratio determined to be outside the range of 0-1..*",
        r"The design coil load is zero for .* The autosize value for maximum water flow rate is zero To change this, input a value for UA, change the heating design day, or raise the   system heating design supply air temperature. Also check to make sure the Preheat   Design Temperature is not the same as the Central Heating Design Supply Air Temperature.",
        r"The design air flow rate is zero for Coil:Cooling:Water = .* The autosize value for max air volume flow rate is zero",

        # Other HVAC
        r"Since Zone Minimum Air Flow Input Method = CONSTANT, input for Fixed Minimum Air Flow Rate will be ignored. Occurs in AirTerminal:SingleDuct:VAV:Reheat = .*",
        r"Since Damper Heating Action = NORMAL, input for Maximum Flow Fraction During Reheat will be ignored. Occurs in AirTerminal:SingleDuct:VAV:Reheat = .*",
        r"In zone .* there is unbalanced air flow. .*",
        r"Calculated design heating load for zone=.* is zero.*",
        r"Calculated design cooling load for zone=.* is zero.*",
        r"In calculating the design coil UA for .* the coil bypass factor is unrealistically large.*",
        r"In calculating the design coil UA for Coil:Cooling:Water .* no apparatus dew-point can be found for the initial entering and leaving conditions.*",
        r"In calculating the design coil UA for Coil:Cooling:Water .* the apparatus dew-point is below the coil design inlet water temperature; the coil outlet design conditions will be changed to correct the problem..*",
        r"In calculating the design coil UA for Coil:Cooling:Water .* the apparatus dew-point is below the coil design inlet water temperature; The initial design conditions are.*",
        r"In calculating the design coil UA for Coil:Cooling:Water .* the outlet chilled water design enthalpy is greater than the inlet air design enthalpy. To correct this condition the design chilled water flow rate will be increased from.*",
        r"The Standard Ratings is calculated for Coil:Cooling:DX:SingleSpeed = .* but not at the AHRI test condition due to curve out of bound. .*",
        r"The Standard Ratings is calculated for Coil:Heating:DX:SingleSpeed = .* but not at the AHRI test condition due to curve out of bound. .*",
        r"Seems like you already tried to get a Handle on this Actuator .*times. Occurred for componentType='SCHEDULE:YEAR', controlType='SCHEDULE VALUE', uniqueKey='.*'.*",
        r"Temperature out of range \[-100. to 200.\] \(PsyPsatFnTemp\)  Routine=PsyTwbFnTdbWPb, .*",
        r"CalculateZoneVolume: .* zone is not fully enclosed..*",
        r"ManageSizing: Calculated Heating Design Air Flow Rate for System=.* is zero.*",
        r"ManageSizing: Calculated Cooling Design Air Flow Rate for System=.* is zero.*",
        r"The .* air loop serves a single zone. The Occupant Diversity was calculated or set to a value less than 1.0..*",
        r"GetDaylightingControls: Fraction of zone or space controlled by the Daylighting reference points is < 1.0. ..discovered in Daylighting:Controls='.*'.*",
        r"Missing temperature setpoint for LeavingSetpointModulated mode Boiler named .*   A temperature setpoint is needed.* ",
        r"Water heater = .*:  Recovery Efficiency and Energy Factor could not be calculated",
        r"ElectricEIRChillerModel - CHILLER:ELECTRIC:EIR '.*' - Air Cooled Condenser Inlet Temperature below 0C.*",
        r"GetElectricEIRChillerInput: Chiller:Electric:EIR='.*' Energy input ratio as a function of temperature curve output is not equal to 1.0.*",
        r"Part-load ratio heating control failed in fan coil unit .*   Bad hot part-load ratio limits.*",
        r"Part-load ratio cooling control failed in fan coil unit .*   Bad part-load ratio limits.*",
        r"Part-load ratio cooling control failed in fan coil unit .*   Iteration limit exceeded in calculating FCU part-load ratio .*",
        r"UpdateZoneSizing: Cooling supply air temperature \(calculated\) within 5C of zone temperature ...check zone thermostat set point and design supply air temperatures ...zone name = .*",
        r"CoolingTower:VariableSpeed '.*' - Tower range temperature is outside model boundaries .*",
        r"CoolingTower:VariableSpeed '.*' - Inlet air wet-bulb temperature is outside model boundaries .*",
        r"CoolingTower:VariableSpeed '.*' - Tower approach temperature is outside model boundaries .*",
        r"CoolingTower:VariableSpeed '.*' - Water flow rate ratio is outside model boundaries .*",
        r"CoolingTower:VariableSpeed '.*' - Cooling tower air flow rate ratio calculation failed .*",
        r"GetSpecificHeatGlycol: Temperature is out of range \(too high\) for fluid \[WATER\] specific heat .*",
        r"GetSpecificHeatGlycol: Temperature is out of range \(too low\) for fluid \[WATER\] specific heat .*",
        r"GetDensityGlycol: Temperature is out of range \(too high\) for fluid \[WATER\] density .*",
        r"GetDensityGlycol: Temperature is out of range \(too low\) for fluid \[WATER\] density .*",
        r"HeatExchanger:AirToAir:SensibleAndLatent '.*' Average air volume flow rate is <50% or >130% of the nominal HX supply air volume flow rate. .*",
        r"Pump nominal power or motor efficiency is set to 0, for pump=.*",
        r"AirLoopHVAC:UnitarySystem =.* Method used to determine the cooling supply air flow rate",
        r"AirLoopHVAC:UnitarySystem =.* Method used to determine the heating supply air flow rate",
        r"GetOAControllerInputs: Controller:MechanicalVentilation='.* Cannot locate a matching DesignSpecification:ZoneAirDistribution object for Zone='.*'. Using default zone air distribution effectiveness of 1.0 for heating and cooling.",
        r"CalcEquipmentFlowRates: '.*' - Target water temperature is greater than the hot water temperature .*",
        r"CalcOAController: Minimum OA fraction > Mechanical Ventilation Controller request for Controller:OutdoorAir=.*, Min OA fraction is used. .*",
        r"InitController: Controller:WaterCoil='.*', Maximum Actuated Flow is zero.",
        r"Controller:MechanicalVentilation='.*', Zone OA/person rate For Zone='.*'. Zone outside air per person rate not set in Design Specification Outdoor Air Object='.*'.",
        r"SizePlantLoop: Calculated Plant Sizing Design Volume Flow Rate=\[0.00\] is too small. Set to 0.0 ..occurs for PlantLoop=.*",
        r"SizePump: Calculated Pump Nominal Volume Flow Rate=\[0.00\] is too small. Set to 0.0 ..occurs for Pump=.*",
        r"Check input. Pump nominal flow rate is set or calculated = 0, for pump=.*",
        r"AirConditioner:VariableRefrigerantFlow '.*'. ...InitVRF: VRF Heat Pump Min/Max Operating Temperature in Heating Mode Limits have been exceeded and VRF system is disabled..*",
        r"AirConditioner:VariableRefrigerantFlow '.*'. ...InitVRF: VRF Heat Pump Min/Max Outdoor Temperature in Heat Recovery Mode Limits have been exceeded and VRF heat recovery is disabled..*",
        r"AirConditioner:VariableRefrigerantFlow '.*'. ...InitVRF: VRF Heat Pump Min/Max Operating Temperature in Cooling Mode Limits have been exceeded and VRF system is disabled..*",
        r"Coil:Cooling:DX:VariableRefrigerantFlow '.*' - Full load outlet air dry-bulb temperature < 2C. This indicates the possibility of coil frost/freeze..*",
        r"AirLoopHVAC:UnitarySystem '.*' ...For fan type and name = Fan:OnOff '.*' ...Fan power ratio function of speed ratio curve has no impact if fan volumetric flow rate is the same as the unitary system volumetric flow rate..*",
        r"ZoneTerminalUnitList '.*'",

        # Refrigeration
        r"GetRefrigerationInput: Refrigeration:System='.*' Suction Piping Zone Name not found .*",
        r"Refrigeration:WalkIn: .*  This walk-in cooler has insufficient capacity to meet the loads.*",

        # Iteration
        r"WetBulb not converged after 101 iterations\(PsyTwbFnTdbWPb\)  Routine=.*",
        r"SimHVAC: Maximum iterations \(.*\) exceeded for all HVAC loops, at .*",
        r"SimHVAC: Maximum iterations \(.*\) exceeded for all HVAC loops, at .* The solution for one or more of the Air Loop HVAC systems did not appear to converge.*",

        # Psychrometrics
        r"Entered Humidity Ratio invalid \(PsyTwbFnTdbWPb\)  Routine=ReportCoilSelection::doFinalProcessingOfCoilData .*",
        r"Temperature out of range \[-100. to 200.\] \(PsyPsatFnTemp\)  Routine=CalcDXHeatingCoil:fullload.*",
        r"Temperature out of range \[-100. to 200.\] \(PsyPsatFnTemp\)  Routine=PsyWFnTdpPb.*",
        r"Temperature out of range \[-100. to 200.\] \(PsyPsatFnTemp\)  Routine=CalcMultiSpeedDXCoil:newdewpointconditions.*",
        r"Enthalpy out of range \(PsyTsatFnHPb\)  Routine=CalcMultiSpeedDXCoil:newdewpointconditions.*",
        r"Enthalpy out of range \(PsyTsatFnHPb\)  Routine=CalcDoe2DXCoil.*",
        r"Enthalpy out of range \(PsyTsatFnHPb\)  Routine=Unknown.*",
        r"Calculated Humidity Ratio invalid \(PsyWFnTdbH\)  Routine=CalcMultiSpeedDXCoil:newdewpointconditions.*",
        r"Calculated Humidity Ratio invalid \(PsyWFnTdbH\)  Routine=CalcDoe2DXCoil.*",
        r"Calculated Humidity Ratio invalid \(PsyWFnTdbH\)  Routine=Unknown.*",
        r"Calculated Relative Humidity out of range \(PsyRhFnTdbWPb\)   Routine=Unknown.*",
        r"Calculated partial vapor pressure is greater than the barometric pressure, so that calculated humidity ratio is invalid \(PsyWFnTdpPb\).  Routine=Unknown.*",
        r"Calculated partial vapor pressure is greater than the barometric pressure, so that calculated humidity ratio is invalid \(PsyWFnTdpPb\).  Routine=Unknown.*",


        # Other
        r"CheckUsedConstructions: There are .* nominally unused constructions in input.",
        r"GetInternalHeatGains: People='.*' has comfort related schedules",
        r"BuildingSurface:Detailed='.*', underground Floor Area = .* ..which does not match its construction area.",
        r"GetSurfaceData: There are .* coincident/collinear vertices; These have been deleted unless the deletion would bring the number of surface sides < 3. For explicit details on each problem surface, use Output:Diagnostics,DisplayExtraWarnings;",
        r"GetSurfaceData: Very small surface area.*, Surface=.*",
        r"Inside surface heat balance did not converge.*",

        # Recurring warnings
        r"Controller:OutdoorAir='.*': Min OA fraction > Mechanical ventilation OA fraction, continues...",
        r"'.*' - Target water temperature should be less than or equal to the hot water temperature error continues...",
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed='.*' - Full load outlet temperature indicates a possibility of frost/freeze error continues..*",
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed='.*': Energy Input Ratio Modifier curve \(function of temperature\) output is negative warning continues...",
        r"CalcDoe2DXCoil: Coil:Cooling:DX:SingleSpeed='.*' - Low condenser dry-bulb temperature error continues...",
        r"CoolingTower:VariableSpeed '.*' - Tower range temperature is out of range error continues...",
        r"Plant loop falling below lower temperature limit, PlantLoop='.*'",
        r"Plant loop exceeding upper temperature limit, PlantLoop='.*'",
        r"Exceeding Maximum iterations for all HVAC loops, during .* continues",
        r"SimHVAC: Exceeding Maximum iterations for all HVAC loops, during .* continues",
        r"AirLoopHVAC:UnitarySystem '.*' - Iteration limit exceeded in calculating sensible part-load ratio error continues..*",
        r"AirLoopHVAC:UnitarySystem '.*' - sensible part-load ratio out of range error continues..*",
        r"Part-load ratio heating control failed in fan coil unit .*",
        r"Part-load ratio cooling iteration limit exceeded in fan coil unit .*",
        r"Part-load ratio cooling control failed in fan coil unit .*",
        r"GetSpecificHeatGlycol: Temperature out of range \(too high\) for fluid \[WATER\] specific heat.*",
        r"GetSpecificHeatGlycol: Temperature out of range \(too low\) for fluid \[WATER\] specific heat.*",
        r"GetDensityGlycol: Temperature out of range \(too high\) for fluid \[WATER\] density.*",
        r"GetDensityGlycol: Temperature out of range \(too low\) for fluid \[WATER\] density.*",
        r"HeatExchanger:AirToAir:SensibleAndLatent '.*':  Average air volume flow rate is <50% or >130% warning continues..*",
        r"Entered Humidity Ratio invalid \(PsyTwbFnTdbWPb\).*",
        r"Enthalpy out of range \(PsyTsatFnHPb\).*",
        r"Calculated Humidity Ratio invalid \(PsyWFnTdbH\).*",
        r"Actual air mass flow rate is smaller than 25% of water-to-air heat pump coil rated air flow rate..*",
        r"WetBulb not converged after max iterations\(PsyTwbFnTdbWPb\).*",
        r"Temperature out of range \[-100. to 200.\] \(PsyPsatFnTemp\).*",
        r"Coil:Cooling:DX:VariableRefrigerantFlow '.*' - Full load outlet temperature indicates a possibility of frost/freeze error continues..*",
        r"HeatExchanger:AirToAir:SensibleAndLatent '.*':  Unbalanced air volume flow ratio exceeds 2:1 warning continues..*",
        r"Entered Humidity Ratio invalid \(PsyWFnTdpPb\).*",
        r"AirConditioner:VariableRefrigerantFlow '.*' -- Exceeded VRF Heat Pump min/max cooling temperature limit error continues.",
        r"AirConditioner:VariableRefrigerantFlow '.*' -- Exceeded VRF Heat Pump min/max heating temperature limit error continues..*",
        r"AirConditioner:VariableRefrigerantFlow '.*' -- Exceeded VRF Heat Recovery min/max outdoor temperature limit error continues..*",
        r"Calculated Relative Humidity out of range \(PsyRhFnTdbWPb\).*",
        r"CoolingTower:VariableSpeed '.*' - Inlet air wet-bulb temperature is out of range error continues...",
        r"CoolingTower:VariableSpeed '.*' - Tower approach temperature is out of range error continues...",
        r"CoolingTower:VariableSpeed '.*' - Water flow rate ratio is out of range error continues...",
        r"Inside surface heat balance convergence problem continues.*",
        r"...Only 1 Terminal Unit connected to system and heat recovery is selected. ...Heat recovery will be disabled.*",
    ]

    for warn_regex in warn_regexs:
        warn_str = warn_regex
        w = re.sub(warn_regex, warn_str, w)

    return (w, n)

def summarize_energyplus_error_files(yml_path):
    """Summarize counts of warnings/errors found in eplusout.err files across an whole ComStock run.

    This function generalizes the warning/error messages found across all previously-extracted
    job*_eplusout.err files and then creates a eplusout_summary.csv file to describe the counts.

    :param yml_path: The path to the YML file used to run buildstockbatch

    :return: None
    """
    # Generalize and count errors from job*.err, run in parallel
    def count_job_errs(job_err_path, errs_dir):
        job_id = re.search(r'.*job(\d+)_eplusout.err', job_err_path).group(1)
        print(f'Summarizing warnings/errors from job {job_id}')
        warn_counts = {}
        with open(job_err_path, 'r') as err_file:
            errs = err_file.read()
            errs = str.replace(errs, "\n   **   ~~~   **", "")  # Replace continuation to make each warning 1 line
            errs = str.replace(errs, "\n   *************  **   ~~~   **", "")

        for line in errs.split('\n'):
            if "** Warning **" in line:
                w, n = generalize_energyplus_error_message(line)
                if w in warn_counts.keys():
                    warn_counts[w] += n
                else:
                    warn_counts[w] = n

        job_gen_errs_name = f'job{job_id}_eplusout_counts.tsv'
        job_gen_errs_path = os.path.join(errs_dir, job_gen_errs_name)
        with open(job_gen_errs_path, 'w') as job_gen_errs:
            for w, n in sorted(warn_counts.items(), key=lambda item: item[1], reverse=True):
                job_gen_errs.write(f'{n}\t{w}\n')

    # Set up output directory
    simulation_output_dir = get_simulation_output_dir_from_yml(yml_path)
    errs_dir = os.path.join(simulation_output_dir, 'eplusout_errors')

    # Generalize and count errors per job and write to file
    err_paths = glob.glob(f'{errs_dir}/job*.err')
    Parallel(n_jobs=-1, verbose=10) (delayed(count_job_errs)(err_path, errs_dir) for err_path in err_paths)

    # Combine counts from all jobs
    warn_counts = {}
    for job_gen_errs_path in glob.glob(f'{errs_dir}/job*_eplusout_counts.tsv'):
        with open(job_gen_errs_path, 'r') as job_gen_errs:
            for line in job_gen_errs:
                n, w = line.split('\t')
                n = int(n)
                if w in warn_counts.keys():
                    warn_counts[w] += n
                else:
                    warn_counts[w] = n

    # Write combined counts to one file
    warn_summary_path = os.path.join(errs_dir, "eplusout_summary.tsv")
    print(f'Writing summary to {warn_summary_path}')
    print(f'The following warnings may need generalization regexes in /comstockpostproc/utils/hpc.py:')
    with open(warn_summary_path, 'w') as f:
        f.write('count\tgeneralized_error\n')
        for w, n in sorted(warn_counts.items(), key=lambda item: item[1], reverse=True):
            f.write(f'{n}\t{w}')
            if not '.*' in w:
                print(f'    {w}')


def summarize_failures(yml_path):
    """Summarize failures across an whole ComStock run.

    This function extracts the ERROR messages for failed runs from the run.log files.

    :param yml_path: The path to the YML file used to run buildstockbatch

    :return: None
    """
    # Extract errors from tar.gz, run in parallel
    def extract_errors_from_tar(tar_path, fails_dir):
        job_id = re.search(r'.*simulations_job(\d+).tar.gz', tar_path).group(1)
        job_fails_name = f'job{job_id}_failures.log'
        job_fails_path = os.path.join(fails_dir, job_fails_name)
        if os.path.exists(job_fails_path):
            print(f'Already extracted failures from job {job_id} to {job_fails_path}')
        else:
            print(f'Extracting failures from job {job_id} to {job_fails_path}')
            with open(job_fails_path, 'w') as job_fails:
                job_fails.write(f'Errors from job_id={job_id}\n')
                with tarfile.open(tar_path) as tar:
                    for tar_member in tar.getmembers():
                        if not 'failed.job' in tar_member.name:
                            continue
                        bldg_id = re.search(r'.*bldg(\d+).*', tar_member.name).group(1)
                        up_id = re.search(r'.*up(\d+).*', tar_member.name).group(1)
                        sing_out_name = f'./up{up_id}/bldg{bldg_id}/openstudio_output.log'
                        job_fails.write(f'Errors from up{up_id}/bldg{bldg_id}\n')
                        try:
                            sing_out_bytes=tar.extractfile(sing_out_name).read()
                            for l in sing_out_bytes.decode().split('\n'):
                                if re.search(r'\[.* ERROR\]|\[.*<Error>.*\]', l):
                                    job_fails.write(f'{l}\n')
                        except KeyError as err:
                            job_fails.write(f'Did not find openstudio_output.log for up{up_id}/bldg{bldg_id}, cannot extract failure details\n')
                    tar.close()
        return

    # Set up output directory
    simulation_output_dir = get_simulation_output_dir_from_yml(yml_path)
    fails_dir = os.path.join(simulation_output_dir, 'failure_summary')
    if not path.exists(fails_dir):
        os.makedirs(fails_dir)

    # Extract the failures per job and write to file
    tar_paths = glob.glob(f'{simulation_output_dir}/simulations_job*.tar.gz')
    Parallel(n_jobs=-1, verbose=10) (delayed(extract_errors_from_tar)(tar_path, fails_dir) for tar_path in tar_paths)

    # Concatenate failures for all jobs into one file
    fail_summary_path = os.path.join(fails_dir, "failure_summary.log")
    print(f'Writing summary to {fail_summary_path}')
    with open(fail_summary_path, 'w') as f:
        for job_fails_path in glob.glob(f'{fails_dir}/job*_failures.log'):
            with open(job_fails_path, 'r') as job_fails:
                for line in job_fails:
                    f.write(line)

def transfer_model_files_to_s3(yml_path, s3_output_dir, oedi_metadata_dir):
    """Copies zipped .osm files from specified ComStock run on Eagle to specified S3 bucket.

    Each upgrade ID will have a folder on S3. The OSM files will be named by building ID and upgrade ID.

    :param yml_path: The path to the YML file used to run buildstockbatch

    :return: None
    """
    # Inputs from project yml file
    with open(yml_path) as proj_yml:
        yml = yaml.load(proj_yml, Loader=yaml.FullLoader)
        output_dir = os.path.normpath(yml['output_directory'])
        simulation_output_dir = os.path.join(output_dir, 'results', 'simulation_output')

    # define S3 path to baseline postprocessed results file
    # this will be used to pull models in the final data set
    df_baseline_results = pd.read_parquet(os.path.join(oedi_metadata_dir, 'baseline.parquet'), engine='pyarrow')
    li_bldg = df_baseline_results.index

    # Make directory for model extractions
    # this is temporary and will be deleted after transfer
    model_files_dir = os.path.join(simulation_output_dir, 'temp_osm_files_for_transfer')
    if not path.exists(model_files_dir):
        os.makedirs(model_files_dir)

    # define function to extract applicable models and send to new location
    def untar_file_to_zip(tar_path):
        li_files_to_delete = []
        job_id = re.search(r'.*simulations_job(\d+).tar.gz', tar_path).group(1)
        print(f"Extracting model files from job {job_id}...", flush=True)
        # loop though tar file
        with tarfile.open(tar_path) as tar:
            zip_count = 0
            model_not_found_count = 0
            for tar_member in tar.getmembers():
                # get data_point zip file for main run only
                if not 'data_point.zip' in tar_member.name:
                    continue
                if 'BuildExistingModel' in tar_member.name:
                    continue
                if 'ApplyUpgrade' in tar_member.name:
                    continue
                # get building ID
                bldg_id = int(re.search(r'.*bldg(\d+).*', tar_member.name).group(1))
                if not bldg_id in li_bldg:
                    continue
                # get upgrade ID
                upgrade_id = re.search(r'.*up(\d+).*', tar_member.name).group(1)
                # add count
                zip_count += 1
                # names for folder and model file
                upgrade_folder = os.path.join(model_files_dir, f"upgrade={upgrade_id}")
                if not path.exists(upgrade_folder):
                    os.makedirs(upgrade_folder)
                model_path_out = os.path.join(upgrade_folder,f"bldg{bldg_id.zfill(7)}-up{upgrade_id}.osm.gz")
                # read zip file and try to find osm file
                datapoint_zip_bytes=tar.extractfile(tar_member).read()
                with zipfile.ZipFile(io.BytesIO(datapoint_zip_bytes)) as zip:
                    try:
                        # unzip model file
                        osm_file = zip.read("in.osm").decode()

                        # write the zipped file
                        with gzip.open(model_path_out, 'wt') as f_out:
                            f_out.write(osm_file)

                        # file will be written, copied to new location, then deleted
                        s3_upgrade_folder = os.path.join(s3_output_dir, f"upgrade={upgrade_id}")
                        s3_model_path = os.path.join(s3_upgrade_folder,f"bldg{bldg_id.zfill(7)}-up{upgrade_id}.osm.gz")
                        if not path.exists(s3_upgrade_folder):
                            os.makedirs(s3_upgrade_folder)

                        # use s5cmd to transfer files to S3
                        result = subprocess.run(['s5cmd', "cp", f'{model_path_out}', f'{s3_model_path}'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) #"--dry-run",
                        #print(result.stdout)
                        #print(result.stderr)

                        # add file to list to be deleted
                        li_files_to_delete.append(model_path_out)

                    # exception if upgrade not found
                    except KeyError as osm_file:
                        model_not_found_count += 1
            # print number of models for files
            print(f"{zip_count} models extracted from job {job_id} -- {model_not_found_count} models were not found.", flush=True)
        tar.close()
        # delete files
        for file in li_files_to_delete:
            if os.path.isfile(file): # this makes the code more robust
                os.remove(file)

    # list of tar files to unzip
    tar_paths = glob.glob(f'{simulation_output_dir}/simulations_job*.tar.gz')

    # run parallel processing
    Parallel(n_jobs=-1, verbose=10) (delayed(untar_file_to_zip)(tar_path) for tar_path in tar_paths)

    # delete temp folder after files moved to S3
    shutil.rmtree(model_files_dir)


def parse_and_generate_profiling(yml_path, worker_number=-1):
    if not(platform == "linux" or platform == "linux2"):
        raise RuntimeError('extract_models_from_simulation_output only works on HPC')

    simulation_output_dir = get_simulation_output_dir_from_yml(yml_path)

    tar_paths = []
    for tar_path in glob.glob(f'{simulation_output_dir}/simulations_job*.tar.gz', recursive=True):
        tar_paths.append(tar_path)
    Parallel(n_jobs=worker_number, verbose=10)(delayed(profilingPerformance.main)(path) for path in tar_paths)

def summarize_hpc_usage(yml_path):
    """Summarize HPC usage of a ComStock run.

    This function extracts the HPC runtime from sampling, simulation, and postprocessing.out files.

    :param yml_path: The path to the YML file used to run buildstockbatch

    :return: None
    """
    # Inputs from project yml file
    with open(yml_path) as proj_yml:
        yml = yaml.load(proj_yml, Loader=yaml.FullLoader)
        output_dir = os.path.normpath(yml['output_directory'])
        simulation_output_dir = os.path.join(output_dir, 'results', 'simulation_output')

    # Output files to parse
    workflow_steps = ['sampling', 'job', 'postprocessing']

    # real time: node-hour

    # user time:
    # CPU time spent executing processes and subprocesses owned by the user rather than system / kernel.
    # Note that CPU time is time used PER CPU
    # i.e. 10 CPUS running simultaneously at 100% in user space for 1 minute
    # would register 600s of user time and 60s of real time

    # sys time:
    # CPU time spent executing the process by the system / kernel.
    # Note that the same CPU time caveats as user time apply.

    # user time and sys time are mutually exclusive and collectively exhaustive,
    # meaning they don't double count and collectively account for all CPU time used within the process tree.

    time_types = ['real', 'user', 'sys']

    times = []
    for workflow_step in workflow_steps:
        print(f'*** {workflow_step} ***')
        glob_path = f'{output_dir}/{workflow_step}.out*'
        for out in glob.glob(glob_path):
            print(out)
            with open(out,'r') as fh:
                for line in fh.readlines():
                    for time_type in time_types:
                        if f'{time_type}\t' in line:
                            time_str = line.replace(f'{time_type}\t', '').strip()
                            # print(f'{time_str} in {time_type}')
                            m, s = time_str.replace('s', '').split('m')
                            # print(f'min: {float(m)}')
                            # print(f'sec: {float(s)}')
                            tot_s = (float(m) * 60.0) + float(s)
                            tot_min = round(tot_s / 60.0)
                            tot_hr = round(tot_min / 60.0, 1)
                            tt_hrs = f'{time_type}_hrs'
                            times.append([workflow_step, tt_hrs, tot_hr])

    # Stop if nothing was found
    if len(times) == 0:
        print(f'ERROR: no runtime info was found in *.out files in {output_dir}')
        exit()

    times_df = pd.DataFrame(times, columns=['workflow_step', 'time_type', 'time_hrs'])

    # Aggregate by workflow step and type
    vals = ['time_hrs']
    ags = [np.sum]
    cols = ['time_type']
    idx = ['workflow_step']  # Rows in Excel pivot table
    pivot = times_df.pivot_table(values=vals, index=idx, columns=cols, aggfunc=ags)
    pivot = pivot.droplevel(level=[0,1], axis=1)

    # Convert to Eagle node hours and AUs
    pivot['eagle_node_hrs'] = round(pivot['real_hrs'])
    pivot['eagle_aus'] = pivot['eagle_node_hrs'] * 3  # 1 Node Hour = 3 AUs on Eagle

    # Print
    print('\n*** Summary ***')
    print(output_dir)
    print('Time in hours')
    print(pivot)

    # Directory to hold the output
    runtime_dir = os.path.join(simulation_output_dir, 'hpc_runtime_summary')
    if not path.exists(runtime_dir):
        os.makedirs(runtime_dir)

    # Write dataframe to a file
    runtime_summary_path = os.path.join(runtime_dir, "hpc_runtime_summary.csv")
    print(f'Writing summary to {runtime_summary_path}')
    pivot.to_csv(runtime_summary_path)