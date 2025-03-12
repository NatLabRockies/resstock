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

def get_git_tracked_csv_files():
    """Get all tracked CSV files in the current directory."""
    result = subprocess.run(
        ["git", "ls-files", "*.csv"],
        capture_output=True,
        text=True,
        cwd=os.path.dirname(os.path.abspath(__file__))
    )
    return [file.strip() for file in result.stdout.splitlines()]

def get_file_from_git(file_path):
    """Get the content of a file from git."""
    result = subprocess.run(
        ["git", "show", f"HEAD:{file_path}"],
        capture_output=True,
        text=True,
        cwd=os.path.dirname(os.path.abspath(__file__))
    )
    return result.stdout

def compare_csv_files(file_path):
    """Compare a CSV file on disk with its version in git."""
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
    git_content = get_file_from_git(rel_path)
    if not git_content:
        return f"File {file_path} not found in git"
    
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
                        f"total: {sum_git:.2f} -> {sum_current:.2f}",
                        sample_changes
                    ))
                else:
                    changed_columns.append((col, f"total: {sum_git:.2f} -> {sum_current:.2f}", None))
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
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Get all tracked CSV files
    csv_files = get_git_tracked_csv_files()
    
    # Check if any files have changed
    changed_files = []
    for file_path in csv_files:
        diff_result = compare_csv_files(file_path)
        if diff_result:
            changed_files.append(diff_result)
    
    if changed_files:
        print("Schedule files that changed:")
        print("")  # Add blank line for readability
        for i, result in enumerate(changed_files):
            print(result)
            # Add blank line between files
            if i < len(changed_files) - 1:
                print("")
        # Exit with error code to fail the CI
        sys.exit(1)
    else:
        print("No changes detected in schedule CSV files.")
        # Exit with success code
        sys.exit(0)

if __name__ == "__main__":
    main() 