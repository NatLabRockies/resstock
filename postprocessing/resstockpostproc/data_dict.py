import pandas as pd
import pathlib
def data_dictionary(df_sdr):
    """
    generate data dictionary based on sdr_column_definitions.csv.
    """
    df_sdr_meta = df_sdr[(df_sdr['Publish In Full'] == 'yes') & (df_sdr['Published Annual Name'].notnull())]
    df_sdr_tsagg = df_sdr[(df_sdr['Timeseries Publish In Full'] == 'yes') & (df_sdr['Published Timeseries Name'].notnull())]

    # metadata_and_annual_results column names, units, and description
    df_meta = df_sdr_meta[['Published Annual Name',
                           'Data Type',
                           'Published Annual Unit',
                           'Notes']].rename(columns={
                               'Published Annual Name': 'field_name',
                               'Data Type': 'data_type',
                               'Published Annual Unit': 'units',
                               'Notes': 'field_description' 
                               })
    df_meta.insert(loc=0, column='field_location', value='metadata_and_annual')

    # timeseries_aggregates column names, units, and description
    df_tsagg_sdr = df_sdr_tsagg[['Published Timeseries Name',
                                 'Data Type',
                                 'Published Timeseries Unit',
                                 'Notes']].rename(columns={
                                     'Published Timeseries Name': 'field_name',
                                     'Data Type': 'data_type',
                                     'Published Timeseries Unit': 'units',
                                     'Notes': 'field_description'
                                     })
    df_tsagg_sdr.insert(loc=0, column='field_location', value='timeseries_aggregates')

    #combine metadata_and_annual_results and timeseries_aggregates
    df_data_dict = pd.concat([df_meta, df_tsagg_sdr], ignore_index=True)
    df_data_dict['units'] = df_data_dict['units'].fillna('n/a')
    
    return df_data_dict

def main():
    here = pathlib.Path(__file__).resolve().parent
    df_sdr = pd.read_csv(here / "resources" / "publication" / "sdr_column_definitions.csv")
    df_data_dict = data_dictionary(df_sdr)
    df_data_dict.to_csv(here / "resources" / "publication" / "data_dictionary.tsv", sep='\t', index=None)


if __name__ == "__main__":
    main()
