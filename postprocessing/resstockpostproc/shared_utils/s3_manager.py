import hashlib
from pathlib import Path
import boto3
import polars as pl


def get_df_from_s3(full_s3_path, cache_dir: Path | None = None) -> pl.DataFrame:
    s3bucket, s3path = full_s3_path.replace("s3://", "").split("/", 1)
    local_path = cache_dir / s3path
    if not _is_file_same(s3bucket, s3path, local_path):
        s3_client = boto3.client("s3")
        print(f"Downloading {s3path} from S3 bucket {s3bucket} to {local_path}")
        if local_path.exists():
            print(" because local file is outdated.")
        local_path.parent.mkdir(parents=True, exist_ok=True)
        s3_client.download_file(s3bucket, s3path, local_path.as_posix())

    if local_path.suffix == ".csv":
        return pl.read_csv(local_path)
    elif local_path.suffix == ".parquet":
        return pl.read_parquet(local_path)
    else:
        raise ValueError(f"Invalid file type for {local_path}")

def _is_file_same(bucket, s3_key, local_path):
    if not local_path.exists():
        return False
    s3 = boto3.client('s3')
    local_md5 = _calculate_md5(local_path)
    s3_metadata = s3.head_object(Bucket=bucket, Key=s3_key)
    s3_etag = s3_metadata['ETag'].strip('"')
    return local_md5 == s3_etag

def _calculate_md5(file_path):
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()