import traceback
import pandas as pd
import pathlib
from typing import Union


def get_error_details() -> str:
    """Get formatted error details including traceback."""
    return traceback.format_exc()


def log_error_details(filename: str):
    """Decorator to log error details to a file."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                error_details = get_error_details()
                with open(filename, 'w') as f:
                    f.write(error_details)
                raise e
        return wrapper
    return decorator


def read_csv(filepath: Union[str, pathlib.Path], **kwargs) -> pd.DataFrame:
    """Read CSV file using pandas with string conversion."""
    return pd.read_csv(filepath, **kwargs)