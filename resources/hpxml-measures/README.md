# OpenStudio®-HPXML

[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/NREL/OpenStudio-HPXML?include_prereleases)](https://github.com/NREL/OpenStudio-HPXML/releases)
[![ci](https://github.com/NREL/OpenStudio-HPXML/actions/workflows/config.yml/badge.svg?branch=master)](https://github.com/NREL/OpenStudio-HPXML/actions/workflows/config.yml)
[![Documentation Status](https://readthedocs.org/projects/openstudio-hpxml/badge/?version=latest)](https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest)

OpenStudio-HPXML allows running residential [EnergyPlus™ simulations](https://energyplus.net/) using an [HPXML file](https://hpxml.nrel.gov/) for the building description.
It is primarily intended to be used by user interfaces or other automated software workflows that automatically produce the HPXML file.

OpenStudio-HPXML can accommodate a wide range of different building technologies and geometries.
End-to-end simulations typically run in 3-10 seconds, depending on complexity, computer platform and speed, etc.

For more information on running simulations, generating HPXML files with the appropriate inputs to run EnergyPlus, etc., please visit the [documentation](https://openstudio-hpxml.readthedocs.io/en/latest).

## Workflows

A simple `run_simulation.rb` script is provided to run a residential EnergyPlus simulation from an HPXML file.
See the [Usage Instructions](https://openstudio-hpxml.readthedocs.io/en/latest/usage_instructions.html) for documentation on running the workflow.

Since [OpenStudio measures](http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/) are used for model generation, additional OpenStudio-based workflows and interfaces can instead be used if desired.

## Capabilities

OpenStudio-HPXML capabilities include:
- Modeling individual dwelling units or whole multifamily buildings
- Modeling a wide range of building technologies
- HVAC design load calculations and equipment autosizing
- Electric panel NEC load calculations (experimental research feature)
- Occupancy schedules (smooth or stochastic)
- Utility bill calculations (flat, tiered, time-of-use, real-time pricing, etc.)
- Emissions calculations (CO2e, etc.)
- Annual and timeseries outputs (energy, loads, temperatures, etc.)
- Optional HPXML inputs with transparent defaults
- Schematron and XSD Schema input validation
- Can be used for [DOE HOMES program approval](https://www.energy.gov/scep/single-family-modeling-solutions-home-efficiency-rebates-program)
- Can be used for [ACCA Manual J approval](https://www.acca.org/standards/approved-software)
- Can be used for [automated calibration to utility bills](https://github.com/NREL/OpenStudio-HPXML-calibration)

## Measures

This repository contains several OpenStudio measures:
- `BuildResidentialHPXML`: A measure that generates an HPXML file from a set of building description inputs (including, e.g., simplified geometry inputs).
- `BuildResidentialScheduleFile`: A measure that generates a CSV of detailed schedules (e.g., stochastic occupancy) for use in the simulation.
- `HPXMLtoOpenStudio`: A measure that translates an HPXML file to an OpenStudio model.
- `ReportSimulationOutput`: A reporting measure that generates a variety of simulation-based annual/timeseries outputs in CSV/JSON/MessagePack format.
- `ReportUtilityBills`: A reporting measure that generates utility bill outputs in CSV/JSON/MessagePack format.

## Users

OpenStudio-HPXML is used by a number of software products or organizations, including:

- [BEopt](https://beopt.nrel.gov)
- [Clarity Heat Pump Toolkit](https://psdconsulting.com/solutions/)
- [Energy Rating Index (ERI)](https://github.com/NREL/OpenStudio-ERI)
- [Home Energy Score](https://www.homeenergyscore.gov)
- [ICF](https://www.icf.com/work/utilities/sightline-utility-customer-programs)
- [OptiMiser](https://optimiserenergy.com)
- [Radiant Labs](https://www.radiantlabs.co)
- [ResStock](https://resstock.nrel.gov/)
- [URBANopt](https://www.nrel.gov/buildings/urbanopt.html)
- [VEIC](https://www.veic.org)
- [Weatherization Assistant](https://weatherization.ornl.gov/softwaredescription/) (pending)
- [XeroHome](https://about.xerohome.com/)

Are you using OpenStudio-HPXML and want to be mentioned here? [Email us](mailto:scott.horowitz@nrel.gov) or [open a Pull Request](https://github.com/NREL/OpenStudio-HPXML/edit/master/README.md).

## License

This project is available under a BSD-3-like license, which is a free, open-source, and permissive license. For more information, check out the [license file](https://github.com/NREL/OpenStudio-HPXML/blob/master/LICENSE.md).
