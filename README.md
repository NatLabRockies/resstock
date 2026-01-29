<img src="https://user-images.githubusercontent.com/1276021/85608250-1ff46b80-b612-11ea-903e-4ced367e5940.jpg" width="280">

The `develop` branch is under active development. Find the latest release [here](https://github.com/NREL/resstock/releases).

[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/NREL/resstock?include_prereleases)](https://github.com/NREL/resstock/releases)
[![ci](https://github.com/NREL/resstock/actions/workflows/config.yml/badge.svg?branch=develop)](https://github.com/NREL/resstock/actions/workflows/config.yml)
[![Documentation Status](https://readthedocs.org/projects/resstock/badge/?version=latest)](https://resstock.readthedocs.io/en/latest/?badge=latest)

[ResStock™](https://www.nrel.gov/buildings/resstock.html), built on the [OpenStudio platform](http://openstudio.net), is a project geared at modeling existing residential building stocks at national, regional, or local scales with a high-degree of granularity (e.g., one physics-based simulation model for every 200 dwelling units), using the [EnergyPlus simulation engine](http://energyplus.net). Information about ComStock™, a sister tool for modeling the commercial building stock, can be found [here](https://www.nrel.gov/buildings/comstock.html). 

This repository contains:

- [Housing characteristics of the U.S. residential building stock](https://github.com/NREL/resstock/tree/main/project_national/housing_characteristics), in the form of conditional probability distributions stored as tab-separated value (.tsv) files. Comments at the bottom of each file document data sources and assumptions for each.
- [A library of housing characteristic "options"](https://github.com/NREL/resstock/blob/main/resources/options_lookup.tsv) that translate high-level characteristic parameters into arguments for OpenStudio measures, and which are referenced by the housing characteristic .tsv files and building energy upgrades defined in project definition files
- Project definition [buildstockbatch YML files](https://github.com/NREL/resstock/blob/main/project_national/national_baseline.yml) openable in any text editor for v2.3.0 and later
- Unit-level [OpenStudio-HPXML Measures](https://github.com/NREL/resstock/tree/main/resources/hpxml-measures) (v3.0.0 and later) for automatically constructing individual representative dwelling unit OpenStudio Models using [OpenStudio-HPXML](https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest)
- [Higher-level OpenStudio Measures](https://github.com/NREL/resstock/tree/main/measures) for controlling simulation inputs and outputs

Software for running ResStock simulations:

 - [Versions 2.3.0](https://github.com/NREL/resstock/releases/tag/v2.3.0) and later only support the use of [buildstockbatch](https://github.com/NREL/buildstockbatch) for deploying simulations on high-performance or cloud computing. Version 2.3.0 also removed separate projects for single-family detached and multifamily buildings, in lieu of a combined `project_national` representing the U.S. residential building stock. See the [changelogs](https://resstock.readthedocs.io/en/latest/changelog/index.html) for more details.
 - For large-scale production runs of ResStock, it is recommended that buildstockbatch is used. For smaller-scale tests, [`run_analysis.rb`](https://github.com/NREL/resstock/blob/develop/workflow/run_analysis.rb) can be used. Information about the workflow can be found in ResStock's [documentation](https://resstock.readthedocs.io/en/latest/basic_tutorial/running_a_project.html#using-run-analysis-rb).
