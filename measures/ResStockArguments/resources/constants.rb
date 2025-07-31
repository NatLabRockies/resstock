# frozen_string_literal: true

module Constants
  Auto = 'auto'
  Heating = 'heating'
  Cooling = 'cooling'
  Weekday = 'weekday'
  Weekend = 'weekend'

  # Exclude these BuildResidentialHPXML arguments as ResStockArguments arguments
  BuildResidentialHPXMLExcludes = ['hpxml_path',
                                   'whole_sfa_or_mf_building_sim',
                                   'schedules_paths',
                                   'simulation_control_timestep',
                                   'simulation_control_run_period',
                                   'geometry_unit_conditioned_floor_area',
                                   'geometry_attached_walls',
                                   'hvac_control_heating_weekday_setpoint',
                                   'hvac_control_heating_weekend_setpoint',
                                   'hvac_control_cooling_weekday_setpoint',
                                   'hvac_control_cooling_weekend_setpoint',
                                   'hvac_cooling_system_integrated_heating_capacity',
                                   'hvac_cooling_system_integrated_heating_load_served',
                                   'utility_bill_scenario',
                                   'utility_bill_scenario_2',
                                   'utility_bill_scenario_3',
                                   'advanced_feature',
                                   'advanced_feature_2',
                                   'additional_properties',
                                   'combine_like_surfaces',
                                   'apply_defaults',
                                   'apply_validation']

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

  # List of ResStockArguments arguments; reported as build_existing_model.<argument_name>, ...
  ArgumentsToRegister = ['heating_unavailable_period',
                         'cooling_unavailable_period',
                         'electric_panel_service_max_current_rating_bin',
                         'electric_panel_service_max_current_rating']

  # List of ResStockArguments arguments; will not be passed into BuildResidentialHPXML
  ArgumentsToExclude = ['heating_unavailable_period',
                        'cooling_unavailable_period',
                        'electric_panel_service_max_current_rating_bin']
end
