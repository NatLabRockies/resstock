# frozen_string_literal: true

module Constants
  Heating = 'heating'
  Cooling = 'cooling'
  Weekday = 'weekday'
  Weekend = 'weekend'

  # Exclude these BuildResidentialHPXML arguments as ResStockArguments arguments
  BuildResidentialHPXMLExcludes = ['hpxml_path',
                                   'geometry_unit_type',
                                   'geometry_unit_conditioned_floor_area']

  # Exclude these BuildResidentialScheduleFile arguments as ResStockArguments arguments
  BuildResidentialScheduleFileExcludes = ['hpxml_path',
                                          'schedules_column_names',
                                          'schedules_random_seed',
                                          'output_csv_path',
                                          'hpxml_output_path',
                                          'append_output',
                                          'debug',
                                          'building_id']

  # Exclude these ResStockArguments from being required in options_lookup.tsv
  # These are arguments added to ResStockArguments not in BuildResidentialHPXML
  OtherExcludes = ['building_id']
end
