"""
2023 NEC New Load Calculations
Process all upgrade files within a directory

Time taken using v2 code with 2023 NEC:
            file        times
18  results_up19  4830.850212
12  results_up13  4816.053314
6   results_up07  4800.770155
13  results_up14  4791.084499
16  results_up17  4782.846577
2   results_up03  4777.145023
11  results_up12  4760.582760
5   results_up06  4758.665472
9   results_up10  4755.117190
4   results_up05  4745.850651
15  results_up16  4741.353851
17  results_up18  4731.831953
8   results_up09  4267.398691
10  results_up11  4179.391637
3   results_up04  4173.802558
1   results_up02  4172.237552
7   results_up08  4003.896083
14  results_up15  3983.834895
0   results_up01  3376.984346
Total time: 85449.69741868973

"""

import argparse
import subprocess
import sys
from pathlib import Path
import time

import pandas as pd


def main(
    directory: Path, 
    plot: bool = False, sfd_only: bool = False, explode_result: bool = False, result_as_map: bool = False, revision: bool = False, ev_level: int = 0):
    
    assert directory.exists(), f"{directory=} does not exist."

    ev_level = int(ev_level)
    match ev_level:
        case 0:
            print("No EVSE scenario.")
            folder_suffix = "_no_ev"
        case 1:
            print("EVSE load level 1 scenario.")
            folder_suffix = "_ev_level1"
        case 2:
            print("EVSE load level 2 scenario.")
            folder_suffix = "_ev_level2"
        case _:
            raise ValueError(f"Unsupported {ev_level=}")

    if revision:
        nec_file = "postprocess_panel_new_load_nec_revision_v2.py"
        msg = "using 2026 NEC REVISION"
        output_folder = f"nec_calculations_revision{folder_suffix}"
    else:
        nec_file = "postprocess_panel_new_load_nec_v2.py"
        msg = "using 2023 NEC"
        output_folder = f"nec_calculations{folder_suffix}"

    upgrade_files = sorted([x for x in directory.glob("*results_up*") if "up00" not in str(x)])
    baseline_file = [x for x in directory.glob("*results_up*") if "up00" in str(x)][0]

    completed_files = []
    output_filedir = directory / output_folder
    output_filedir.mkdir(exist_ok=True, parents=True)
    for file in output_filedir.glob("*results_up*"):
        completed_upgrade = file.stem[:12]
        completed_files.append(
            Path(str(baseline_file).replace("results_up00", completed_upgrade))
            )

    upgrade_files = [x for x in upgrade_files if x not in completed_files]
    print(f"Processing {len(upgrade_files)} upgrade files in directory, {msg}")
    print(f"{len(completed_files)} files completed...")
    for i, file in enumerate(upgrade_files,1):
        print(f" {i}. {file}")

    failed_files = []
    successful_file_times = []
    for file in upgrade_files:
        try:
            start_time = time.time()
            cli_cmd = ["python", nec_file, str(baseline_file), str(file)]
            if explode_result:
                cli_cmd.append("-x")
            if result_as_map:
                cli_cmd.append("-m")
            if plot:
                cli_cmd.append("-p")
            if sfd_only:
                cli_cmd.append("-d")
            if ev_level:
                cli_cmd.extend(["-e", str(ev_level)])
            print()
            print(cli_cmd)
            result = subprocess.run(
                    cli_cmd,
                    capture_output=True,
                    check=True,
                    text=True,
                )
            print(f"stdout=\n{result.stdout}")
            if result.stderr:
                print(f"stderr=\n{result.stderr}")
            if (
                "crashed with returncode" in result.stdout
                or "crashed with returncode" in result.stderr
            ):
                failed_files.append(file)
            else:
                elapsed_time = time.time() - start_time
                successful_file_times.append(
                    (file.stem, elapsed_time)
                )
        except subprocess.CalledProcessError as exp:
            print("Caught file processing failure")
            print(
                f"{file} crashed with returncode={exp.returncode}, "
                f"\nERROR_output= {exp.output}, "
                f"\nERROR_stdout= {exp.stdout}, "
                f"\nERROR_stderr= {exp.stderr} "
            )
            failed_files.append(file)
    file_times = pd.DataFrame.from_records(
        successful_file_times, columns=["file", "times"]
    )
    file_times = file_times.sort_values(["times"], ascending=False)
    print(file_times)
    print(f"Total time: {file_times['times'].sum()}")
    if failed_files:
        print("The following file(s) failed with error: ")
        print(*failed_files, sep="\n")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "directory",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock result directory."
        )
    parser.add_argument(
        "-p",
        "--plot",
        action="store_true",
        default=False,
        help="Make plots based on expected output file without regenerating output_file",
    )
    parser.add_argument(
        "-d",
        "--sfd_only",
        action="store_true",
        default=False,
        help="Apply calculation to Single-Family Detached only (this is only on plotting for now)",
    )
    parser.add_argument(
        "-x",
        "--explode_result",
        action="store_true",
        default=False,
        help="Whether to export intermediate calculations as part of the results (useful for debugging)",
    )
    parser.add_argument(
        "-m",
        "--result_as_map",
        action="store_true",
        default=False,
        help="Whether to export NEC calculation result as a building_id map only. "
        "Default to appending NEC result as new column(s) to input result file. ",
    )
    parser.add_argument(
        "-r",
        "--revision",
        action="store_true",
        default=False,
        help="Whether to run calculations from 2026 Revision",
    )
    parser.add_argument(
        "-e",
        "--ev_level",
        action="store",
        default=0,
        type=int,
        help="Level of EVSE load to add: 0 (no EVSE), 1 (EVSE level 1), 2 (EVSE level 2). Only applicable for 220.83 load summing method. Default is 0.",
    )

    args = parser.parse_args()
    main(
        Path(args.directory),
        plot=args.plot, sfd_only=args.sfd_only, explode_result=args.explode_result, result_as_map=args.result_as_map, revision=args.revision, ev_level=args.ev_level
        )
