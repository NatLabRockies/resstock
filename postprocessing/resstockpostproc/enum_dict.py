import pandas as pd
import pathlib


def enum(df):
    """
    enumerations for a dataframe
    """
    df_enum = (
        pd.concat(
            [pd.DataFrame({'metadata_column': col, 'enumeration': df[col].unique()})
             for col in df.columns],
             ignore_index=True
             )
             )
    
    return df_enum


def enum_dict(df_data_dict, df_bs_csv, df_meta_up, up_files):
    #format buildstock.csv column names
    df_bs_csv.columns = ['in.' + col.lower().replace(' ', '_') for col in df_bs_csv.columns]
    df_bs_csv = df_bs_csv.drop('in.building', axis=1)
    df_bs_csv =  df_bs_csv.rename(columns={
        'in.ashrae_iecc_climate_zone_2004_-_sub-cz_split': 'in.ashrae_iecc_climate_zone_2004_sub_cz_split',
        'in.income_recs2015': 'in.income_recs_2015',
        'in.income_recs2020': 'in.income_recs_2020'
        })

    #enumerations from buildstock.csv
    df_enum_bs_csv = enum(df_bs_csv)

    df_data_dict_filter = df_data_dict[df_data_dict['field_location'] == 'metadata_and_annual']
    data_dict_columns = df_data_dict_filter['field_name']
    data_dict_columns = [x for x in data_dict_columns if not x.startswith(("out.", "calc.weighted", "bldg_id"))]

    bs_csv_columns = df_bs_csv.columns
    leftover_columns = list(set(data_dict_columns) - set(bs_csv_columns))
    
    #enumerations from released data
    df_enum_meta = pd.DataFrame(columns=['metadata_column', 'enumeration'])
    for up in up_files:
        existing_cols = [c for c in leftover_columns if c in df_meta_up[up].columns]
        df_meta_filter = df_meta_up[up][existing_cols]
        df_meta_filter_enum = enum(df_meta_filter)
        df_enum_meta = pd.concat([df_enum_meta, df_meta_filter_enum]).drop_duplicates(keep='first')
    
    df_enum_dict = pd.concat([df_enum_bs_csv, df_enum_meta]).drop_duplicates(keep='first')
    df_enum_dict = df_enum_dict.dropna(subset=['enumeration'])
    df_enum_dict = df_enum_dict.sort_values(by=['metadata_column', 'enumeration'])

    return df_enum_dict


def main():
    here = pathlib.Path(__file__).resolve().parent
    test_path = here.parent.parent
    df_data_dict = pd.read_csv(here / "resources" / "publication" / "data_dictionary.tsv", sep='\t')
    df_bs_csv = pd.read_csv(test_path / "test" / "base_results" / "baseline"/ "annual"/ "buildstock.csv")
    df_meta_up = {}
    up_path = (test_path / "test" / "base_results" / "upgrades"/ "sdr_annual")
    up_files = [f.name for f in up_path.glob('*.csv')]
    for up in up_files:
        df_meta_up[up] = pd.read_csv(test_path / "test" / "base_results" / "upgrades"/ "sdr_annual"/ up)

    df_enum_dict = enum_dict(df_data_dict, df_bs_csv, df_meta_up, up_files)
    df_enum_dict.to_csv(here / "resources" / "publication" / "enumeration_dictionary.tsv", sep='\t', index=None)


if __name__ == "__main__":
    main()