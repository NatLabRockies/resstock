# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
class UnitsMixin():
    # Constants for unit conversion
    # Created using OpenStudio unit conversion library
    UNIT_CONVERSIONS = {
        'kwh_to_kwh' : 1,
        'kwh_to_mwh' : 1e-3,
        'mwh_to_kwh' : 1e3,
        'twh_to_kwh' : 1e9,
        'mbtu_to_kbtu' : 1000,
        'kwh_to_kbtu' : 3.412141633127942,
        'kwh_to_tbtu' : ((1.0 / 1e9) * 3.412141633127942),
        'kbtu_to_kwh': (1.0 / 3.412141633127942),
        'therm_to_kbtu' : 100,
        'therm_to_kwh' : (100 / 3.412141633127942),
        'kbtu_to_tbtu' : (1.0 / 1e9),
        'tbtu_to_kbtu' : 1e9,
        'btu_to_kbtu' : (1.0 / 1e3),
        'million_btu_to_kbtu': (1e9 / 1e6),
        'million_btu_to_kwh': (1000 / 3.412141633127942),
        'gj_to_kbtu' : 947.8171203133173,
        'gj_to_kwh' : 277.77777777777777,
        'w_per_m2_k_to_btu_per_ft2_f_hr': 0.17611,
        'pa_to_inwc': 0.004015,
        'w_per_m2_to_w_per_ft2': (1.0/10.763910416709722),
        'co2e_kg_to_co2e_mmt': (0.000000001),
        'co2e_kg_to_co2e_metric_ton': 0.001
    }

    def conv_fact(self, from_unit, to_unit):
        conv_string = f'{from_unit}_to_{to_unit}'
        if conv_string in self.UNIT_CONVERSIONS:
            return self.UNIT_CONVERSIONS[conv_string]
        else:
            raise KeyError(f'Conversion from {from_unit} to {to_unit} \
            not defined in UnitsMixin UNIT_CONVERSIONS, add it there.')

    def convert(self, value, from_unit, to_unit):
        conversion_factor = self.conv_fact(from_unit, to_unit)
        return value * conversion_factor

    def nice_units(self, units):
        units = units.replace('_per_', '/')
        units = units.replace('ft2', '$\mathrm{ft^{2}}$')
        units = units.replace('m2', '$\mathrm{m^{2}}$')
        units = units.replace('m3', '$\mathrm{m^{3}}$')
        return units
