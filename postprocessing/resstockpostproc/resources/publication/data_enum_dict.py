import pandas as pd
from functools import reduce

def data_dictionary(df_meta_up0, df_tsagg_up0, df_sdr):
    """
    generate data dictionary based on released resstock baseline annual 
    and timeseries data and sdr_column_definitions.csv.
    """

    # metadata_and_annual_results column names, units, and description
    col_df_meta = pd.DataFrame(df_meta_up0.columns, columns=["field_name"])
    col_df_meta['field_location'] = 'metadata_and_annual'
    col_df_meta_sdr = df_sdr[['Published Annual Name',
                              'Published Annual Unit',
                              'Notes']].rename(columns={
                                  'Published Annual Name': 'field_name',
                                  'Published Annual Unit': 'units',
                                  'Notes': 'field_description'
                                  })
    df_meta = pd.merge(
        col_df_meta, col_df_meta_sdr, on="field_name", how="left"
        )

    # timeseries_aggregates column names, units, and description
    col_df_tsagg = pd.DataFrame(df_tsagg_up0.columns, columns=["field_name"])
    col_df_tsagg['field_location'] = 'timeseries_aggregates'
    col_df_tsagg_sdr = df_sdr[['Published Timeseries Name',
                              'Published Timeseries Unit',
                              'Notes']].rename(columns={
        'Published Timeseries Name': 'field_name',
        'Published Timeseries Unit': 'units',
        'Notes': 'field_description'
        })
    df_tsagg = pd.merge(col_df_tsagg, col_df_tsagg_sdr, on="field_name", how="left")

    #combine metadata_and_annual_results and timeseries_aggregates
    df_dict = pd.concat([df_meta, df_tsagg], ignore_index=True)
    df_dict['units'] = df_dict['units'].fillna('n/a')
    
    return df_dict


def chunk_list(lst, n):
    """Split list into chunks of size n"""
    for i in range(0, len(lst), n):
        yield lst[i:i+n]


def split_list(df):
    """
    Split long list in the allowable_enumerations 
    column into chunks of size n
    """
    ids_to_split = ["in.representative_income", "in.county_and_puma"]
    chunk_size = 1000

    rows = []
    for _, row in df.iterrows():
        if row["field_name"] in ids_to_split:
            # break into chunks
            for chunk in chunk_list(row["allowable_enumerations"], chunk_size):
                rows.append({"field_name": row["field_name"],
                             "data_type": row["data_type"],
                             "allowable_enumerations": chunk})
        else:
            # keep as is
            rows.append({"field_name": row["field_name"],
                         "data_type": row["data_type"],
                         "allowable_enumerations":row["allowable_enumerations"]})

    formating_df = pd.DataFrame(rows)
    
    return formating_df


def isfloat(string):
    """try convert string values to float"""
    try:
        float(string)
        return True
    except:
        return False  
    

def convert_to_numeric(s):
    """Converts string values to int or float values if possible"""
    if not type(s) == str:
        return s
    
    if s.isnumeric():
        return int(s)
    elif isfloat(s):
        return float(s)
    else:
        return s
        

def safe_key(x):
    """Generate a safe sort key for mixed-type values."""
    if x is None:
        return (2, 0)  # None last
    try:
        return (0, float(x))  # numeric values
    except (ValueError, TypeError):
        return (1, str(x))    # strings


def detect_dtype(values):
    """Detect the data type of a sequence of values."""
    vals = [v for v in values if v is not None]
    lowered = {str(v).strip().lower() for v in vals}

    boolean_sets = [
        {"yes", "no"},
        {"true", "false"}
    ]
    if any(lowered.issubset(bs) for bs in boolean_sets):
        return "bool"

    return str(pd.Series(vals).dtypes)

        
def convert_to_int(df):
    """
    Convert the values in allowable_enumerations column to int
    for specific fields identified by prefix matching.
    """
    prefixes = (
        "in.electric_panel_service_rating..a", 
        "in.electric_panel_breaker_space_total_count",
        "out.params.panel_breaker_space"
    )

    mask = df["field_name"].str.startswith(prefixes, na=False)

    df.loc[mask, "allowable_enumerations"] = df.loc[mask, "allowable_enumerations"].apply(
        lambda lst: [int(x) if x not in (None, "None") else None for x in lst]
        )

    return df
    

def revise_data_type(df):
    """Revise the data type assignments in a DataFrame based on field name"""
    dtype_float_prefixes = ["in.representative_income", "out.", "calc.weighted"]
    dtype_float_end_strs = ["charges", "rates", "fees"]
    dtype_integer_end_strs = ["count", "..w", "..a"]
    dtype_integer = ["in.electric_panel_service_rating..a",
                     "in.electric_panel_breaker_space_total_count",
                     "in.geometry_building_number_units_mf",
                     "in.geometry_building_number_units_sfa"]
    dtype_boolean = ["out.params.panel_constraint_capacity.2023_nec_existing_dwelling_load_based",
                     "out.params.panel_constraint_breaker_space"]
    dtype_string = ["bldg_id",
                    "out.params.panel_constraint_overall.2023_nec_existing_dwelling_load_based"]
    
    df.loc[df["field_name"].str.startswith(tuple(dtype_float_prefixes), na=False), \
           "data_type"] = "float"
    mask = df["field_name"].str.startswith("in.utility_bill", na=False) & \
        df["field_name"].str.endswith(tuple(dtype_float_end_strs), na=False)
    df.loc[mask, "data_type"] = "float"
    mask = df["field_name"].str.startswith("out.", na=False) & \
        df["field_name"].str.endswith(tuple(dtype_integer_end_strs), na=False)
    df.loc[mask, "data_type"] = "integer"
    df.loc[df["field_name"].isin(dtype_integer), "data_type"] = "integer"
    df.loc[df["field_name"].isin(dtype_boolean), "data_type"] = "boolean"
    df.loc[df["field_name"].isin(dtype_string), "data_type"] = "string"

    return df


def enum(df):
    """get allowable enumerations for the input dataframe for each columns."""
    enums = {
        col: [convert_to_numeric(s) for s in sorted(df[col].unique(), key=safe_key)]
        for col in df.columns
        }
    enums_list = list(enums.values())
    dtypes = {k: detect_dtype(v) for k, v in enums.items()}
    
    df_enums = pd.DataFrame({'field_location': 'metadata_and_annual', 
                            'field_name':df.columns, 
                            'data_type': list(dtypes.values()),
                            'allowable_enumerations': enums_list})

    dtype_map = {
        'float64': 'float',
        'int64': 'integer',
        'object': 'string',
        'bool': 'boolean'
        }

    df_enums['data_type'] = df_enums['data_type'].map(dtype_map)
    df_enums = convert_to_int(df_enums)
    df_enums = split_list(df_enums)

    return df_enums


def merge_dfs(dfs):
    """
    Merge a list of DataFrames on 'field_name', combining 'data_type' and 'allowable_enumerations'.

    Rules:
    - field_name is the same across all DataFrames.
    - data_type: if any of the DataFrames has a non-boolean type, use that type; 
                 if all are boolean, keep 'boolean'.
    - allowable_enumerations: combine all lists, keep unique values, and sort them.
    """

    # Start with field_name from the first df
    field_names = dfs[0]['field_name']
    merged = pd.DataFrame({'field_name': field_names})

    # Combine data_type
    def combine_dtype_fn(field):
        types = [df.loc[df['field_name'] == field, 'data_type'].values[0] for df in dfs]
        non_bool = [t for t in types if t != 'boolean']
        return non_bool[0] if non_bool else 'boolean'
    merged['data_type'] = merged['field_name'].apply(combine_dtype_fn)

    # Combine allowable_enumerations
    def combine_enums_fn(field):
        vals = []
        for df in dfs:
            vals.extend(df.loc[df['field_name'] == field, 'allowable_enumerations'].values[0])
        return sorted(set(vals), key=safe_key)
    merged['allowable_enumerations'] = merged['field_name'].apply(combine_enums_fn)

    return merged

def enum_dict(df_data_dict, df_meta_up0, dfs_meta_up, up_list):
    """
    generate enumeration dictionary based on data dictionary, 
    released resstock baseline and upgrade annual results
    """
    #add baseline unique values to data dictionary
    df_meta_up0 = df_meta_up0.drop(columns=df_meta_up0.columns[
        df_meta_up0.columns.str.startswith(("out.", "calc.weighted", "bldg_id"))
        ])
    df_baseline_enum = enum(df_meta_up0)
    df_enum_dict = pd.merge(df_data_dict, df_baseline_enum, on="field_name", how="left")

    # add upgrade values to data dictionary
    upgrade_dfs = []
    prefixes = ("upgrade",
                "out.params.panel_breaker_space",
                "out.params.panel_constraint")
    for up in up_list:
        filtered_df = dfs_meta_up[up].loc[:, dfs_meta_up[up].columns.str.startswith(prefixes)]
        temp = enum(filtered_df)
        upgrade_dfs.append(temp)  

    upgrade_merged_df = merge_dfs(upgrade_dfs)
    df_enum_dict = (
        df_enum_dict.merge(upgrade_merged_df, on="field_name", how="left", suffixes=("", "_new"))
        .assign(
            allowable_enumerations=lambda d: d["allowable_enumerations_new"].combine_first(d["allowable_enumerations"]),
            data_type=lambda d: d["data_type_new"].combine_first(d["data_type"])
            )
            .drop(columns=["allowable_enumerations_new", "data_type_new", "field_description"])
            )
    df_enum_dict = revise_data_type(df_enum_dict)

    df_enum_dict = df_enum_dict.fillna({'data_type': 'n/a', 'allowable_enumerations': 'n/a'})
    df_enum_dict['allowable_enumerations'] = df_enum_dict['allowable_enumerations'].apply(
        lambda x: "|".join(map(str, x)) if isinstance(x, (list, tuple)) else str(x)
        )

    return df_enum_dict


def main():
    df_sdr = pd.read_csv("sdr_column_definitions.csv")
    df_meta_up0 = pd.read_parquet("metadata_and_annual_results/upgrade0.parquet")
    df_tsagg_up0 = pd.read_parquet("timeseries_aggregates/up00.parquet")

    dfs_meta_up = {}
    up_list = [0,1,2,3]
    for up in up_list:
        dfs_meta_up[up] = pd.read_parquet(f"metadata_and_annual_results/upgrade{up}.parquet")
    
    df_data_dict = data_dictionary(df_meta_up0, df_tsagg_up0, df_sdr)
    df_data_dict.to_csv("data_dictionary.tsv", sep='\t', index=None)

    df_enum_dict = enum_dict(df_data_dict, df_meta_up0, dfs_meta_up, up_list)
    df_enum_dict.to_csv("enumeration_dictionary.tsv", sep='\t', index=None)


main()
"""
To run this code, you need download relevant OEDI data from resstock_amy2018_release_1
field_name column values come from baseline metadata_and_annual_results and timeseries_aggregates.

field_location column values are assigned based on the source of the field name:
"metadata_and_annual" if the field name is from baseline metadata_and_annual_results
"timeseries_aggregates" if the field name is from timeseries_aggregates

units column values are obtained from sdr_column_definitions.csv.

field_description values are taken from sdr_column_definitions.csv.

allowable_enumerations come from baseline metadata_and_annual_results 
and upgrade metadata_and_annual_results. If a field represents a continuous 
value (e.g., out.site_energy.net.energy_savings..kwh), enumerations are omitted.

data_type is derived from allowable_enumerations.
"""