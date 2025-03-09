"""
2023 NEC New Load Calculations
Process all upgrade files within a directory

"""

import argparse
import subprocess
import sys
from pathlib import Path
import time

import pandas as pd


def main(
    directory: Path, 
    plot: bool = False, sfd_only: bool = False, explode_result: bool = False, result_as_map: bool = False, oedi_data_format: bool = False):
    
    assert directory.exists(), f"{directory=} does not exist."
    nec_file = "postprocess_panel_new_load_nec_for_sdr_2024_2.py"
    msg = "using 2023 NEC"
    output_folder = "nec_calculations"

    upgrade_files = sorted([x for x in directory.glob("*metadata_and_annual_results*") if "upgrade" in str(x)])
    baseline_file = [x for x in directory.glob("*metadata_and_annual_results*") if "baseline" in str(x)][0]

    upgrades_to_skip = [5, 10, 15] # <--- with geothermal
    upgrade_files = [x for x in upgrade_files if int(x.stem.removeprefix("upgrade").removesuffix("_metadata_and_annual_results")) not in upgrades_to_skip]
    print(f"Skipping geothermal upgrades: {upgrades_to_skip}")

    completed_files = []
    output_filedir = directory / output_folder
    output_filedir.mkdir(exist_ok=True, parents=True)
    for file in output_filedir.glob("*metadata_and_annual_results*"):
        completed_upgrade = file.stem[:9]
        completed_files.append(
            Path(str(baseline_file).replace("baseline", completed_upgrade))
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
            if oedi_data_format:
                cli_cmd.append("-o")
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
        "-o",
        "--oedi_data_format",
        action="store_true",
        default=False,
        help="Used to process Standard Dataset stored on OEDI, which has in.xxx format"
        "Default to processing normal ResStock run output, which has build_existing_model.xxx format. ",
    )

    args = parser.parse_args()
    main(
        Path(args.directory),
        plot=args.plot, sfd_only=args.sfd_only, explode_result=args.explode_result, result_as_map=args.result_as_map, oedi_data_format=args.oedi_data_format
        )
