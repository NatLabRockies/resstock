#!/usr/bin/env python3
"""
Script to check for failed simulations in ResStock results CSV files.
Uses Polars LazyFrames for memory efficiency.
"""

import sys
import polars as pl
from pathlib import Path
from typing import List, Dict, Any, Optional
import argparse


def get_failures(csv_path: str, verbose: bool = False) -> List[Dict[str, Any]]:
    """
    Identify failed simulations in a ResStock results CSV file.
    
    Args:
        csv_path: Path to CSV file
        verbose: Whether to print detailed information during processing
        
    Returns:
        List of dictionaries containing details of failed simulations
    """
    path = Path(csv_path)
    if not path.exists():
        print(f"Error: File {csv_path} does not exist.")
        return [{"building_id": "N/A",  
                 "completed_status": "N/A",
                 "step_failures": f"Path {csv_path} does not exist."}]
    
    if verbose:
        print(f"Checking file: {csv_path}")
    
    # Use LazyFrame for memory efficiency
    try:
        # Scan the CSV lazily
        df_lazy = pl.scan_csv(csv_path)
        
        # Check if completed_status column exists
        schema = df_lazy.collect_schema()
        if 'completed_status' not in schema:
            print(f"Warning: 'completed_status' column not found in {csv_path}")
            return [{"building_id": "N/A",
                     "completed_status": "N/A",
                     "step_failures": f"completed_status column not found in {csv_path}"}]
        
        if 'step_failures' not in schema:
            # all simulations are successful so there is no step_failures column
            return []
        
        # Extract only the columns we need for failure reporting
        columns_to_select = ['building_id', 'completed_status', 'step_failures']
        
        # Filter to only failed simulations and collect
        failed_sims = (
            df_lazy
            .select(columns_to_select)
            .filter(pl.col('completed_status') == 'Fail')
            .collect()
        )
        
        # Convert to list of dictionaries
        failures = failed_sims.to_dicts() if not failed_sims.is_empty() else []
        
        return failures
        
    except Exception as e:
        print(f"Error processing {csv_path}: {str(e)}")
        return [{"building_id": "N/A",
                 "completed_status": "N/A",
                 "step_failures": f"Error processing {csv_path}: {str(e)}"}]


def print_failures(failures: List[Dict[str, Any]], csv_path: str) -> None:
    """
    Print information about failed simulations.
    
    Args:
        failures: List of dictionaries containing details of failed simulations
        csv_path: Path to CSV file (for reporting)
    """
    if not failures:
        return
    
    print(f"Found {len(failures)} failures in {csv_path}:")
    
    for i, failure in enumerate(failures, 1):
        building_id = failure.get('building_id', 'N/A')
        step_failures = failure.get('step_failures', 'N/A')
        
        print(f"  {i}. Building ID: {building_id}")
        
        # Handle step_failures formatting
        try:
            # Use ast.literal_eval to safely parse Python literal syntax
            import ast
            
            # If step_failures is a string representation of a Python list
            if isinstance(step_failures, str) and step_failures.strip().startswith('['):
                # Parse the Python literal string into a Python object
                failures_data = ast.literal_eval(step_failures)
                print("     Step Failures:")
                
                # Format each failure entry
                for idx, failure_entry in enumerate(failures_data, 1):
                    # Extract measure name
                    measure = failure_entry.get('measure_dir_name', 'Unknown')
                    print(f"       - Measure: {measure}")
                    
                    # Format step errors
                    if 'step_errors' in failure_entry and failure_entry['step_errors']:
                        print("         Errors:")
                        for error_idx, error in enumerate(failure_entry['step_errors'], 1):
                            # Format traceback with proper indentation
                            error_lines = error.split('\n')
                            print(f"           {error_idx}. {error_lines[0]}")
                            for line in error_lines[1:]:
                                print(f"              {line}")
                    else:
                        print("         No specific error details available")
            else:
                # If not JSON or other format, print as is
                print(f"     Step Failures: {step_failures}")
        except (ValueError, SyntaxError, AttributeError):
            # If parsing fails, fall back to original display
            print(f"     Step Failures: {step_failures}")


def main():
    """Main function to parse arguments and check for failures."""
    parser = argparse.ArgumentParser(
        description="Check for failed simulations in ResStock results CSV files."
    )
    parser.add_argument(
        "csv_file", 
        help="Path to the CSV file to check for failures."
    )
    parser.add_argument(
        "--verbose", "-v", 
        action="store_true", 
        help="Enable verbose output."
    )
    parser.add_argument(
        "--exit-code", "-e", 
        action="store_true", 
        help="Exit with non-zero code if failures are found."
    )
    
    args = parser.parse_args()
    
    failures = get_failures(args.csv_file, args.verbose)
    print_failures(failures, args.csv_file)
    
    if args.exit_code and failures:
        print(f"ERROR: {len(failures)} simulation(s) failed. Check the logs above for details.")
        sys.exit(1)
    
    if not failures:
        print("All simulations completed successfully.")


if __name__ == "__main__":
    main()
