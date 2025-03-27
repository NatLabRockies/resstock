# Stochastic Occupancy Modeling

The `BuildResidentialScheduleFile` measure introduces major changes to most occupant-related schedules.

## Overview

Occupant activities are now generated on-the-fly and saved to CSV files used by OpenStudio/EnergyPlus `Schedule:File` objects.
Schedules are generated using time-inhomogenous Markov chains derived from American Time Use Survey data, supplemented with sampling duration and power level from NEEA RBSA data, as well as DHW draw duration and flow rate data from Aquacraft/AWWA data.
See [Stochastic simulation of occupant-driven energy use in a bottom-up residential building stock model](https://www.sciencedirect.com/science/article/pii/S0306261922011540) for a more complete description of the methodology.

## Outputs

The `BuildResidentialScheduleFile` measure outputs schedule CSV files (available inside the `run` folder of each building simulation output).
The schedule CSV file contains the following columns:
* `occupants`
* `lighting_interior`
* `lighting_garage`
* `cooking_range`
* `dishwasher`
* `clothes_washer`
* `clothes_dryer`
* `ceiling_fan`
* `plug_loads_other`
* `plug_loads_tv`
* `hot_water_dishwasher`
* `hot_water_clothes_washer`
* `hot_water_fixtures`
* `sleeping` (exported only when "debug" mode is enabled)

Each of the columns, except `occupants`, represent schedule values (kW for power schedules, and gallons per minute for water schedules) normalized using universal maximum values found in `constants.rb`.

The `occupants` column represents the fractional percent of occupants present out of the total number of occupants assigned to the unit.
The `sleeping` column represents the fractional percent of the total number of occupants who are sleeping.

There are the same number of rows as the total simulation time-step (e.g., 35040 if 15-min, 8760 if hourly [8784, if leap year]).

## The `ScheduleGenerator`

This class uses Markov chain based simulation to generate the schedule CSV files.
To support that, several pre-generated set of files are used, contained in the following folders:
* `weekday`
* `weekend`

These two folders contain the Markov chain initial probability, Markov chain transition and also appliance duration probabilities CSV files.
The appliance duration probabilities here are used during the Markov chain simulation to determine duration of various appliances.
The first column of each file indicates the four clusters (0 to 3), for 4 occupant behavior types.

The following sections describe the remaining files found in the schedule generator resources folder.

### `<enduse>_consumption_dist.csv`

These files contain the 15-min power consumption kWh samples for the given end use, obtained from RBSA (average 15-min end use kWh for each submetered home; N=number of homes with that end use).
The schedule generator randomly picks one of these values to determine the power level of the appliance schedule.

Here, `<enduse>` may be:
* `clothes_dryer`
* `clothes_washer`
* `cooking`
* `dishwasher`

### `<enduse>_duration_dist.csv`

These files contain the samples of runtime duration of different end uses, in 15-min increments, generated from the RBSA dataset.
So, a value of 3 means 45 minutes.
Each row is for one household, and each column is the duration of one instance of the appliance running.

Again, `<enduse>` may be:
* `clothes_dryer`
* `clothes_washer`
* `cooking`
* `dishwasher`

### `<enduse>_cluster_size_probability.csv`

These files contain the probability distribution of the event cluster size for different domestic hot water end uses, obtained from the HotWaterEventScheduleGenerator Excel file.
The first row is the probability of a cluster size of 1 event, second row for probability of cluster size of 2 events and so on.

Here, `<enduse>` may be:
* `hot_water_clothes_washer`
* `hot_water_dishwasher`
* `shower`

### `<enduse>_event_duration_probability.csv`

TODO

Again, `<enduse>` may be:
* `hot_water_clothes_washer`
* `hot_water_dishwasher`
* `shower`

### `constants.rb` and `schedules.csv`

These files contain various miscellaneous configurations for the schedule generator.
Their meanings and sources are defined below.

#### Occupancy Types

Occupancy cluster types: Mostly Home, Early Regular Worker, Mostly Away, Regular Worker.
Probabilities are derived from ATUS using the k-modes algorithm.

#### Plug Loads

This is the baseline schedule for misc plugload, lighting and ceiling fan.
It will be modified based on occupancy.
Television plugload uses the same schedule as misc plugload.

#### Lighting

Indoor lighting schedule is generated on the fly.
Garage lighting uses the same schedule as indoor lighting.

#### Cooking

Monthly energy use multipliers for cooking stove/oven/range from average of multiple end-use submetering datasets (HEMS, RBSAM, ELCAP, Mass Res 1, Pecan St.).
Power draw distribution is based on csv files.

#### Clothes Dryer

Monthly energy use multipliers for clothes dryer from average of multiple end-use submetering datasets (HEMS, RBSAM, ELCAP, Mass Res 1, Pecan St., FSEC).
Power draw distribution is based on csv files.

#### Clothes Washer

Monthly energy use multipliers for clothes washer and dishwasher from average of multiple end-use submetering datasets (generally HEMS, RBSAM, ELCAP, Mass Res 1, and Pecan St.).
Power draw distribution is based on csv files.

#### Dishwasher

Monthly energy use multipliers for clothes washer and dishwasher from average of multiple end-use submetering datasets (generally HEMS, RBSAM, ELCAP, Mass Res 1, Pecan St., and FSEC).
Power draw distribution is based on csv files.

#### Water Draw Events

Probabilities for all water draw events are extracted from DHW event generators.
The onset, duration, events_per_cluster_probs, flow rate mean and std could all refer to the DHW event generator excel sheet ('event characteristics' and 'Start Times' sheet).

#### Sink

avg_sink_clusters_per_hh -> Average sink cluster per house hold. Set to 6657 for U.S. average of 2.53 occupants per household, based on relationship of 6885 clusters for 25 gpd, from Building America DHW Event Schedule Generator,
Set to 6657 for U.S. average of 2.53 occupants per household, based on relationship of 6885 clusters for 25 gpd, from Building America DHW Event Schedule Generator.
