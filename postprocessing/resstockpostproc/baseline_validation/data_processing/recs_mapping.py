from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP

import polars as pl
from typing import Literal

def add_enduse_columns(df: pl.DataFrame) -> pl.DataFrame:
    new_columns = []
    for output_col, recs_column in RECS_ENDUSE_MAP.items():
        if isinstance(recs_column, tuple):
            new_columns.append(
                pl.sum_horizontal(
                    pl.col(col_description["column_name"]) *
                    pl.lit(col_description["factor"]) for col_description in recs_column
                ).alias(output_col)
            )
        else:
            new_columns.append(
                (pl.col(recs_column["column_name"]) *
                pl.lit(recs_column["factor"])).alias(output_col)
            )
    return df.with_columns(new_columns)


def add_characteristic_columns(df: pl.DataFrame, data_source: str) -> pl.DataFrame:
    new_columns = []
    for output_col, char_map in RECS_CHARS_MAPPING.items():
        column_definition = char_map[data_source]
        if column_definition["column_name"] not in df.columns:
            continue
        new_columns.append(
            pl.col(column_definition["column_name"]).replace_strict(
                   column_definition["mapping"],
                   default=pl.col(column_definition["column_name"])
            ).alias(output_col)
        )
    return df.with_columns(new_columns)
