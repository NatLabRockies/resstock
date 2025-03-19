#!/usr/bin/env python3
"""
Script to print detailed differences between schedule CSV files in git.
Compares the current state of files on disk with the committed versions.
Returns exit code 1 if differences are found, 0 otherwise.
"""

import os
import subprocess
import pandas as pd
import sys
import argparse

def get_git_tracked_csv_files():
    """Get all tracked CSV files in the current directory."""
    result = subprocess.run(
        ["git", "ls-files", "*.csv"],
        capture_output=True,
        text=True,
        cwd=os.path.dirname(os.path.abspath(__file__))
    )
    return [file.strip() for file in result.stdout.splitlines()]

def get_file_from_git(file_path, branch=None):
    """Get the content of a file from git.

    Args:
        file_path: Path to the file
        branch: Optional branch name to get the file from
    """
    ref = branch if branch else "HEAD"
    result = subprocess.run(
        ["git", "show", f"{ref}:{file_path}"],
        capture_output=True,
        text=True,
        cwd=os.path.dirname(os.path.abspath(__file__))
    )
    return result.stdout

def calculate_avg_daily_profile(series):
    """Calculate the average daily profile from a time series.

    Args:
        series: A pandas Series containing schedule values

    Returns:
        A list of 24 hourly average values, or None if series length doesn't match expected
    """
    length = len(series)

    # Determine resolution based on length
    if length in [8760, 8784]:  # Hourly data (standard year or leap year)
        values_per_hour = 1
    elif length in [17520, 17568]:  # 30-minute data (standard year or leap year)
        values_per_hour = 2
    elif length in [35040, 35136]:  # 15-minute data (standard year or leap year)
        values_per_hour = 4
    elif length in [52560, 52704]:  # 10-minute data (standard year or leap year)
        values_per_hour = 6
    else:
        return None  # Unsupported series length

    days = length // (24 * values_per_hour)

    # Reshape to (days, 24, values_per_hour)
    try:
        reshaped = series.values.reshape(days, 24, values_per_hour)
        # Average across days and sub-hourly values
        avg_daily = reshaped.mean(axis=0).mean(axis=1)
        return avg_daily
    except ValueError:
        # If reshape fails (e.g., length not divisible), return None
        return None

def plot_daily_profiles(avg_profile_git, avg_profile_current, column_name, output_dir=None):
    """Create a plot comparing before and after daily profiles.

    Args:
        avg_profile_git: List of 24 hourly values from git version
        avg_profile_current: List of 24 hourly values from current version
        column_name: Name of the column/schedule being compared
        output_dir: Directory to save the plot (if None, just display)

    Returns:
        Path to saved figure or None if just displayed
    """
    # Import matplotlib only when this function is called
    import matplotlib.pyplot as plt
    
    if avg_profile_git is None or avg_profile_current is None:
        return None

    hours = list(range(24))

    plt.figure(figsize=(10, 6))
    plt.plot(hours, avg_profile_git, 'b-', label='Before')
    plt.plot(hours, avg_profile_current, 'r-', label='After')
    plt.xlabel('Hour of Day')
    plt.ylabel('Average Value')
    plt.title(f'Daily Profile Comparison: {column_name}')
    plt.xticks(range(0, 24, 2))
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.legend()

    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        safe_name = column_name.replace('/', '_').replace('\\', '_').replace(':', '_').replace(' ', '')
        fig_path = os.path.join(output_dir, f"{safe_name}_profile_comparison.png")
        plt.savefig(fig_path)
        plt.close()
        return fig_path
    else:
        plt.show()
        plt.close()
        return None

def compare_csv_files(file_path, branch=None, plot_profiles=False, output_dir=None):
    """Compare a CSV file on disk with its version in git.

    Args:
        file_path: Path to the file
        branch: Optional branch name to compare against
        plot_profiles: Whether to generate plots for profile comparisons
        output_dir: Directory to save plots if plot_profiles is True
    """
    # Get the directory of the script
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Construct the full path to the file
    full_path = os.path.join(script_dir, os.path.basename(file_path))

    # Get the relative path from the git root
    git_root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        cwd=script_dir
    ).stdout.strip()

    rel_path = os.path.relpath(full_path, git_root)

    # Read the current file from disk
    try:
        df_current = pd.read_csv(full_path)
    except Exception as e:
        return f"Error reading current file {file_path}: {str(e)}"

    # Get the file content from git
    git_content = get_file_from_git(rel_path, branch)
    if not git_content:
        return f"File {file_path} not found in {'branch ' + branch if branch else 'git'}"

    # Write git content to a temporary file and read it
    temp_file = os.path.join(script_dir, "temp_git_file.csv")
    with open(temp_file, "w") as f:
        f.write(git_content)

    try:
        df_git = pd.read_csv(temp_file)
        os.remove(temp_file)  # Clean up
    except Exception as e:
        if os.path.exists(temp_file):
            os.remove(temp_file)  # Clean up
        return f"Error reading git version of {file_path}: {str(e)}"

    # Compare the dataframes
    if df_current.equals(df_git):
        return None  # No differences

    # Check for shape differences
    shape_changed = df_current.shape != df_git.shape

    # Find changed and unchanged columns
    changed_columns = []
    unchanged_columns = []
    all_columns = set(df_current.columns) | set(df_git.columns)

    for col in all_columns:
        if col not in df_current.columns:
            changed_columns.append((col, "Column removed", None))
            continue
        if col not in df_git.columns:
            changed_columns.append((col, "Column added", None))
            continue

        # Check if column values are different
        if not df_current[col].equals(df_git[col]):
            # Calculate sum for numeric columns
            if pd.api.types.is_numeric_dtype(df_current[col]) and pd.api.types.is_numeric_dtype(df_git[col]):
                sum_git = df_git[col].sum()
                sum_current = df_current[col].sum()

                # Count non-zero values
                nonzero_git = (df_git[col] != 0).sum()
                nonzero_current = (df_current[col] != 0).sum()

                # Calculate average daily profile
                avg_profile_git = calculate_avg_daily_profile(df_git[col])
                avg_profile_current = calculate_avg_daily_profile(df_current[col])

                # Display before and after profiles
                profile_diff = ""
                if avg_profile_git is not None and avg_profile_current is not None:
                    before_values = [f"{val:.2f}" for val in avg_profile_git]
                    after_values = [f"{val:.2f}" for val in avg_profile_current]

                    profile_diff = f"      daily average profile (24 hourly values):\n"
                    profile_diff += f"       before: [{', '.join(before_values)}]\n"
                    profile_diff += f"       after:  [{', '.join(after_values)}]"

                # Get sample of changed values
                diff_mask = df_current[col] != df_git[col]
                if diff_mask.any():
                    sample_indices = diff_mask.to_numpy().nonzero()[0][:2]  # Get up to 2 changed indices
                    sample_changes = []
                    for idx in sample_indices:
                        if idx < len(df_git) and idx < len(df_current):
                            sample_changes.append(f"row {idx}: {df_git.iloc[idx][col]} -> {df_current.iloc[idx][col]}")

                    changed_columns.append((
                        col, 
                        f"total: {sum_git:.2f} -> {sum_current:.2f}\n      non-zero values: {nonzero_git} -> {nonzero_current}\n{profile_diff}",
                        sample_changes
                    ))
                else:
                    changed_columns.append((col, f"total: {sum_git:.2f} -> {sum_current:.2f}\nnon-zero values: {nonzero_git} -> {nonzero_current}", None))
            else:
                # For non-numeric columns, show a few examples of changes
                diff_mask = df_current[col] != df_git[col]
                if diff_mask.any():
                    sample_indices = diff_mask.to_numpy().nonzero()[0][:2]  # Get up to 2 changed indices
                    sample_changes = []
                    for idx in sample_indices:
                        if idx < len(df_git) and idx < len(df_current):
                            sample_changes.append(f"row {idx}: '{df_git.iloc[idx][col]}' -> '{df_current.iloc[idx][col]}'")

                    changed_columns.append((col, "Values changed", sample_changes))
                else:
                    changed_columns.append((col, "Values changed", None))
        else:
            unchanged_columns.append(col)

    # Format the output
    result = []
    result.append("=" * 80)
    result.append(f"FILE: {os.path.basename(file_path)}")
    if branch:
        result.append(f"COMPARING: Current state vs branch '{branch}'")
    result.append("=" * 80)

    # Add summary section
    result.append("SUMMARY:")
    result.append(f"  - {len(changed_columns)} columns changed, {len(unchanged_columns)} columns unchanged")
    if shape_changed:
        result.append(f"  - Rows: {len(df_git)} -> {len(df_current)}")
    result.append("")

    # List unchanged columns
    if unchanged_columns:
        result.append("UNCHANGED COLUMNS:")
        # Format in multiple rows if there are many columns
        chunks = [sorted(unchanged_columns)[i:i+5] for i in range(0, len(unchanged_columns), 5)]
        for chunk in chunks:
            result.append(f"  {', '.join(chunk)}")
        result.append("")

    # List changed columns with details
    if changed_columns:
        result.append("CHANGED COLUMNS:")

        for i, (col, change, samples) in enumerate(changed_columns):
            result.append(f"  - {col}:")
            result.append(f"      {change}")

            # Generate plot for this column if requested and it has profile data
            if plot_profiles and 'daily average profile' in change:
                # Extract profiles from the existing data
                avg_profile_git = calculate_avg_daily_profile(df_git[col])
                avg_profile_current = calculate_avg_daily_profile(df_current[col])

                if avg_profile_git is not None and avg_profile_current is not None:
                    plot_path = plot_daily_profiles(
                        avg_profile_git,
                        avg_profile_current,
                        f"{os.path.basename(file_path)}: {col}",
                        output_dir
                    )
                    if plot_path:
                        result.append(f"      Plot saved to: {plot_path}")

            if samples:
                result.append(f"      Sample changes:")
                for sample in samples:
                    result.append(f"        - {sample}")

            # Add a blank line between columns except after the last one
            if i < len(changed_columns) - 1:
                result.append("")

    return "\n".join(result)

def main():
    """Main function to compare all CSV files."""
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Compare CSV files with git versions')
    parser.add_argument('--with', dest='branch', help='Compare with specified branch instead of HEAD')
    parser.add_argument('--plot', action='store_true', help='Generate plots for daily profile comparisons')
    parser.add_argument('--output-dir', default='profile_plots', help='Directory to save plots (default: profile_plots)')
    args = parser.parse_args()

    # Import matplotlib only if plotting is enabled
    if args.plot:
        try:
            import matplotlib.pyplot as plt
        except ImportError:
            print("Warning: matplotlib is required for plotting but could not be imported.")
            print("Continuing without plot generation.")
            args.plot = False

    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # Create output directory if plotting is enabled
    output_dir = None
    if args.plot:
        output_dir = os.path.join(script_dir, args.output_dir)
        os.makedirs(output_dir, exist_ok=True)

    # Get all tracked CSV files
    csv_files = get_git_tracked_csv_files()

    # Check if any files have changed
    changed_files = []
    for file_path in csv_files:
        diff_result = compare_csv_files(file_path, args.branch, args.plot, output_dir)
        if diff_result:
            changed_files.append(diff_result)

    if changed_files:
        print("Schedule files that changed:")
        if args.branch:
            print(f"Comparing current state with branch: {args.branch}")
        print("")  # Add blank line for readability
        for i, result in enumerate(changed_files):
            print(result)
            # Add blank line between files
            if i < len(changed_files) - 1:
                print("")
        # Exit with error code to fail the CI
        sys.exit(1)
    else:
        if args.branch:
            print(f"No changes detected in schedule CSV files compared to branch: {args.branch}")
        else:
            print("No changes detected in schedule CSV files.")
        # Exit with success code
        sys.exit(0)

if __name__ == "__main__":
    main() 