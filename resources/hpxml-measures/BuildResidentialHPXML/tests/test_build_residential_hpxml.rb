# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class BuildResidentialHPXMLTest < Minitest::Test
  def setup
    @output_path = File.join(File.dirname(__FILE__), 'extra_files')
    @model_save = false # true helpful for debugging, i.e., can render osm in 3D
  end

  def teardown
    FileUtils.rm_rf(@output_path) if !@model_save
  end

  def test_workflows
    # Extra buildings that don't correspond with sample files
    hpxmls_files = {
      # Base files to derive from
      'base-sfd.xml' => nil,
      'base-sfd2.xml' => 'base-sfd.xml',

      'base-sfa.xml' => 'base-sfd.xml',
      'base-sfa2.xml' => 'base-sfa.xml',
      'base-sfa3.xml' => 'base-sfa.xml',

      'base-mf.xml' => 'base-sfd.xml',
      'base-mf2.xml' => 'base-mf.xml',
      'base-mf3.xml' => 'base-mf.xml',
      'base-mf4.xml' => 'base-mf.xml',

      'base-sfd-header.xml' => 'base-sfd.xml',
      'base-sfd-header-no-duplicates.xml' => 'base-sfd-header.xml',

      # Extra files to test
      'extra-auto.xml' => 'base-sfd.xml',
      'extra-auto-duct-locations.xml' => 'extra-auto.xml',
      'extra-pv-roofpitch.xml' => 'base-sfd.xml',
      'extra-dhw-solar-latitude.xml' => 'base-sfd.xml',
      'extra-second-refrigerator.xml' => 'base-sfd.xml',
      'extra-second-heating-system-portable-heater-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-fireplace-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-boiler-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-portable-heater-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-second-heating-system-fireplace-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-second-heating-system-boiler-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-enclosure-windows-shading.xml' => 'base-sfd.xml',
      'extra-enclosure-garage-partially-protruded.xml' => 'base-sfd.xml',
      'extra-enclosure-garage-atticroof-conditioned.xml' => 'base-sfd.xml',
      'extra-enclosure-atticroof-conditioned-eaves-gable.xml' => 'base-sfd.xml',
      'extra-enclosure-atticroof-conditioned-eaves-hip.xml' => 'extra-enclosure-atticroof-conditioned-eaves-gable.xml',
      'extra-gas-pool-heater-with-zero-kwh.xml' => 'base-sfd.xml',
      'extra-gas-hot-tub-heater-with-zero-kwh.xml' => 'base-sfd.xml',
      'extra-no-rim-joists.xml' => 'base-sfd.xml',
      'extra-iecc-zone-different-than-epw.xml' => 'base-sfd.xml',
      'extra-state-code-different-than-epw.xml' => 'base-sfd.xml',
      'extra-time-zone-different-than-epw.xml' => 'base-sfd.xml',
      'extra-emissions-fossil-fuel-factors.xml' => 'base-sfd.xml',
      'extra-bills-fossil-fuel-rates.xml' => 'base-sfd.xml',
      'extra-seasons-building-america.xml' => 'base-sfd.xml',
      'extra-ducts-crawlspace.xml' => 'base-sfd.xml',
      'extra-ducts-attic.xml' => 'base-sfd.xml',
      'extra-water-heater-crawlspace.xml' => 'base-sfd.xml',
      'extra-water-heater-attic.xml' => 'base-sfd.xml',
      'extra-battery-crawlspace.xml' => 'base-sfd.xml',
      'extra-battery-attic.xml' => 'base-sfd.xml',
      'extra-vehicle-ev.xml' => 'extra-enclosure-garage-partially-protruded.xml',
      'extra-two-batteries.xml' => 'base-sfd.xml',
      'extra-detailed-performance-autosize-cooling-system.xml' => 'base-sfd.xml',
      'extra-detailed-performance-autosize-heat-pump.xml' => 'base-sfd.xml',
      'extra-detailed-performance-autosize-heat-pump2.xml' => 'extra-detailed-performance-autosize-heat-pump.xml',
      'extra-power-outage-periods.xml' => 'base-sfd.xml',

      'extra-sfa-atticroof-flat.xml' => 'base-sfa.xml',
      'extra-sfa-atticroof-conditioned-eaves-gable.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-atticroof-conditioned-eaves-hip.xml' => 'extra-sfa-atticroof-conditioned-eaves-gable.xml',
      'extra-mf-eaves.xml' => 'extra-mf-slab.xml',

      'extra-sfa-slab.xml' => 'base-sfa.xml',
      'extra-sfa-vented-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-unvented-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-conditioned-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-unconditioned-basement.xml' => 'base-sfa.xml',
      'extra-sfa-ambient.xml' => 'base-sfa.xml',

      'extra-sfa-rear-units.xml' => 'base-sfa.xml',
      'extra-sfa-exterior-corridor.xml' => 'base-sfa.xml',

      'extra-sfa-slab-middle.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-slab-right.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-vented-crawlspace-middle.xml' => 'extra-sfa-vented-crawlspace.xml',
      'extra-sfa-vented-crawlspace-right.xml' => 'extra-sfa-vented-crawlspace.xml',
      'extra-sfa-unvented-crawlspace-middle.xml' => 'extra-sfa-unvented-crawlspace.xml',
      'extra-sfa-unvented-crawlspace-right.xml' => 'extra-sfa-unvented-crawlspace.xml',
      'extra-sfa-unconditioned-basement-middle.xml' => 'extra-sfa-unconditioned-basement.xml',
      'extra-sfa-unconditioned-basement-right.xml' => 'extra-sfa-unconditioned-basement.xml',

      'extra-mf-atticroof-flat.xml' => 'base-mf.xml',
      'extra-mf-atticroof-vented.xml' => 'base-mf.xml',

      'extra-mf-slab.xml' => 'base-mf.xml',
      'extra-mf-vented-crawlspace.xml' => 'base-mf.xml',
      'extra-mf-unvented-crawlspace.xml' => 'base-mf.xml',
      'extra-mf-ambient.xml' => 'base-sfa.xml',

      'extra-mf-rear-units.xml' => 'base-mf.xml',
      'extra-mf-exterior-corridor.xml' => 'base-mf.xml',

      'extra-mf-slab-left-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-left-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-left-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-vented-crawlspace-left-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-left-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-left-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-top.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-top.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-top.xml' => 'extra-mf-unvented-crawlspace.xml',

      'extra-mf-slab-rear-units.xml' => 'extra-mf-slab.xml',
      'extra-mf-vented-crawlspace-rear-units.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-rear-units.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-slab-left-bottom-rear-units.xml' => 'extra-mf-slab-left-bottom.xml',
      'extra-mf-slab-left-middle-rear-units.xml' => 'extra-mf-slab-left-middle.xml',
      'extra-mf-slab-left-top-rear-units.xml' => 'extra-mf-slab-left-top.xml',
      'extra-mf-slab-middle-bottom-rear-units.xml' => 'extra-mf-slab-middle-bottom.xml',
      'extra-mf-slab-middle-middle-rear-units.xml' => 'extra-mf-slab-middle-middle.xml',
      'extra-mf-slab-middle-top-rear-units.xml' => 'extra-mf-slab-middle-top.xml',
      'extra-mf-slab-right-bottom-rear-units.xml' => 'extra-mf-slab-right-bottom.xml',
      'extra-mf-slab-right-middle-rear-units.xml' => 'extra-mf-slab-right-middle.xml',
      'extra-mf-slab-right-top-rear-units.xml' => 'extra-mf-slab-right-top.xml',
      'extra-mf-vented-crawlspace-left-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-left-bottom.xml',
      'extra-mf-vented-crawlspace-left-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-left-middle.xml',
      'extra-mf-vented-crawlspace-left-top-rear-units.xml' => 'extra-mf-vented-crawlspace-left-top.xml',
      'extra-mf-vented-crawlspace-middle-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-bottom.xml',
      'extra-mf-vented-crawlspace-middle-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-middle.xml',
      'extra-mf-vented-crawlspace-middle-top-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-top.xml',
      'extra-mf-vented-crawlspace-right-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-right-bottom.xml',
      'extra-mf-vented-crawlspace-right-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-right-middle.xml',
      'extra-mf-vented-crawlspace-right-top-rear-units.xml' => 'extra-mf-vented-crawlspace-right-top.xml',
      'extra-mf-unvented-crawlspace-left-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-bottom.xml',
      'extra-mf-unvented-crawlspace-left-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-middle.xml',
      'extra-mf-unvented-crawlspace-left-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-top.xml',
      'extra-mf-unvented-crawlspace-middle-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-bottom.xml',
      'extra-mf-unvented-crawlspace-middle-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-middle.xml',
      'extra-mf-unvented-crawlspace-middle-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-top.xml',
      'extra-mf-unvented-crawlspace-right-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-bottom.xml',
      'extra-mf-unvented-crawlspace-right-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-middle.xml',
      'extra-mf-unvented-crawlspace-right-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-top.xml',

      'error-heating-system-and-heat-pump.xml' => 'base-sfd.xml',
      'error-cooling-system-and-heat-pump.xml' => 'base-sfd.xml',
      'error-sfd-conditioned-basement-zero-foundation-height.xml' => 'base-sfd.xml',
      'error-sfd-adiabatic-walls.xml' => 'base-sfd.xml',
      'error-mf-bottom-crawlspace-zero-foundation-height.xml' => 'base-mf.xml',
      'error-second-heating-system-but-no-primary-heating.xml' => 'base-sfd.xml',
      'error-second-heating-system-ducted-with-ducted-primary-heating.xml' => 'base-sfd.xml',
      'error-sfa-no-building-num-units.xml' => 'base-sfa.xml',
      'error-sfa-above-apartment.xml' => 'base-sfa.xml',
      'error-sfa-below-apartment.xml' => 'base-sfa.xml',
      'error-sfa-all-adiabatic-walls.xml' => 'base-sfa.xml',
      'error-mf-no-building-num-units.xml' => 'base-mf.xml',
      'error-mf-all-adiabatic-walls.xml' => 'base-mf.xml',
      'error-mf-two-stories.xml' => 'base-mf.xml',
      'error-mf-conditioned-attic.xml' => 'base-mf.xml',
      'error-dhw-indirect-without-boiler.xml' => 'base-sfd.xml',
      'error-conditioned-attic-with-one-floor-above-grade.xml' => 'base-sfd.xml',
      'error-zero-number-of-bedrooms.xml' => 'base-sfd.xml',
      'error-sfd-with-shared-system.xml' => 'base-sfd.xml',
      'error-rim-joist-height-but-no-assembly-r.xml' => 'base-sfd.xml',
      'error-rim-joist-assembly-r-but-no-height.xml' => 'base-sfd.xml',
      'error-unavailable-period-args-not-all-specified' => 'base-sfd.xml',
      'error-unavailable-period-args-not-all-same-size.xml' => 'base-sfd.xml',
      'error-unavailable-period-window-natvent-invalid.xml' => 'base-sfd.xml',
      'error-heating-perf-data-not-all-specified.xml' => 'base-sfd.xml',
      'error-cooling-perf-data-not-all-specified.xml' => 'base-sfd.xml',
      'error-emissions-args-not-all-specified.xml' => 'base-sfd.xml',
      'error-emissions-args-not-all-same-size.xml' => 'base-sfd.xml',
      'error-emissions-natural-gas-args-not-all-specified.xml' => 'base-sfd.xml',
      'error-bills-args-not-all-same-size.xml' => 'base-sfd.xml',
      'error-invalid-aspect-ratio.xml' => 'base-sfd.xml',
      'error-negative-foundation-height.xml' => 'base-sfd.xml',
      'error-too-many-floors.xml' => 'base-sfd.xml',
      'error-invalid-garage-protrusion.xml' => 'base-sfd.xml',
      'error-sfa-no-non-adiabatic-walls.xml' => 'base-sfa.xml',
      'error-hip-roof-and-protruding-garage.xml' => 'base-sfd.xml',
      'error-protruding-garage-under-gable-roof.xml' => 'base-sfd.xml',
      'error-ambient-with-garage.xml' => 'base-sfd.xml',
      'error-invalid-door-area.xml' => 'base-sfd.xml',
      'error-invalid-window-aspect-ratio.xml' => 'base-sfd.xml',
      'error-garage-too-wide.xml' => 'base-sfd.xml',
      'error-garage-too-deep.xml' => 'base-sfd.xml',
      'error-vented-attic-with-zero-floor-insulation.xml' => 'base-sfd.xml',
      'error-different-software-program.xml' => 'base-sfd-header.xml',
      'error-different-simulation-control.xml' => 'base-sfd-header.xml',
      'error-same-emissions-scenario-name.xml' => 'base-sfd-header.xml',
      'error-same-utility-bill-scenario-name.xml' => 'base-sfd-header.xml',
      'error-could-not-find-epw-file.xml' => 'base-sfd.xml',

      'warning-non-electric-heat-pump-water-heater.xml' => 'base-sfd.xml',
      'warning-sfd-slab-non-zero-foundation-height.xml' => 'base-sfd.xml',
      'warning-mf-bottom-slab-non-zero-foundation-height.xml' => 'base-mf.xml',
      'warning-slab-non-zero-foundation-height-above-grade.xml' => 'base-sfd.xml',
      'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-vented-attic-with-floor-and-roof-insulation.xml' => 'base-sfd.xml',
      'warning-unvented-attic-with-floor-and-roof-insulation.xml' => 'base-sfd.xml',
      'warning-conditioned-basement-with-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-conditioned-attic-with-floor-insulation.xml' => 'base-sfd.xml',
      'warning-geothermal-loop-but-no-gshp.xml' => 'base-sfd.xml'
    }

    expected_errors = {
      'error-heating-system-and-heat-pump.xml' => ['Multiple central heating systems are not currently supported.'],
      'error-cooling-system-and-heat-pump.xml' => ['Multiple central cooling systems are not currently supported.'],
      'error-sfd-conditioned-basement-zero-foundation-height.xml' => ["Foundation type of 'ConditionedBasement' cannot have a height of zero."],
      'error-sfd-adiabatic-walls.xml' => ['No adiabatic surfaces can be applied to single-family detached homes.'],
      'error-mf-conditioned-basement' => ['Conditioned basement/crawlspace foundation type for apartment units is not currently supported.'],
      'error-mf-conditioned-crawlspace' => ['Conditioned basement/crawlspace foundation type for apartment units is not currently supported.'],
      'error-mf-bottom-crawlspace-zero-foundation-height.xml' => ["Foundation type of 'UnventedCrawlspace' cannot have a height of zero."],
      'error-second-heating-system-but-no-primary-heating.xml' => ['A second heating system was specified without a primary heating system.'],
      'error-second-heating-system-ducted-with-ducted-primary-heating.xml' => ["A ducted heat pump with 'separate' ducted backup is not supported."],
      'error-sfa-no-building-num-units.xml' => ['Did not specify the number of units in the building for single-family attached or apartment units.'],
      'error-sfa-above-apartment.xml' => ['Single-family attached units cannot be above another unit.'],
      'error-sfa-below-apartment.xml' => ['Single-family attached units cannot be below another unit.'],
      'error-sfa-all-adiabatic-walls.xml' => ['At least one wall must be set to non-adiabatic.'],
      'error-mf-no-building-num-units.xml' => ['Did not specify the number of units in the building for single-family attached or apartment units.'],
      'error-mf-all-adiabatic-walls.xml' => ['At least one wall must be set to non-adiabatic.'],
      'error-mf-two-stories.xml' => ['Apartment units can only have one above-grade floor.'],
      'error-mf-conditioned-attic.xml' => ['Conditioned attic type for apartment units is not currently supported.'],
      'error-dhw-indirect-without-boiler.xml' => ['Must specify a boiler when modeling an indirect water heater type.'],
      'error-conditioned-attic-with-one-floor-above-grade.xml' => ['Units with a conditioned attic must have at least two above-grade floors.'],
      'error-sfd-with-shared-system.xml' => ['Specified a shared system for a single-family detached unit.'],
      'error-rim-joist-height-but-no-assembly-r.xml' => ['Specified a rim joist height but no rim joist assembly R-value.'],
      'error-rim-joist-assembly-r-but-no-height.xml' => ['Specified a rim joist assembly R-value but no rim joist height.'],
      'error-unavailable-period-args-not-all-specified' => ['Did not specify all required unavailable period arguments.'],
      'error-unavailable-period-args-not-all-same-size.xml' => ['One or more unavailable period arguments does not have enough comma-separated elements specified.'],
      'error-unavailable-period-window-natvent-invalid.xml' => ["Window natural ventilation availability 'invalid' during an unavailable period is invalid."],
      'error-heating-perf-data-not-all-specified.xml' => ['Did not specify all required heating detailed performance data arguments.'],
      'error-cooling-perf-data-not-all-specified.xml' => ['Did not specify all required cooling detailed performance data arguments.'],
      'error-emissions-args-not-all-specified.xml' => ['Did not specify all required emissions arguments.'],
      'error-emissions-args-not-all-same-size.xml' => ['One or more emissions arguments does not have enough comma-separated elements specified.'],
      'error-emissions-natural-gas-args-not-all-specified.xml' => ['Did not specify fossil fuel emissions units for natural gas emissions values.'],
      'error-bills-args-not-all-same-size.xml' => ['One or more utility bill arguments does not have enough comma-separated elements specified.'],
      'error-invalid-aspect-ratio.xml' => ['Aspect ratio must be greater than zero.'],
      'error-negative-foundation-height.xml' => ['Foundation height cannot be negative.'],
      'error-too-many-floors.xml' => ['Number of above-grade floors must be six or less.'],
      'error-invalid-garage-protrusion.xml' => ['Garage protrusion fraction must be between zero and one.'],
      'error-sfa-no-non-adiabatic-walls.xml' => ['At least one wall must be set to non-adiabatic.'],
      'error-hip-roof-and-protruding-garage.xml' => ['Cannot handle protruding garage and hip roof.'],
      'error-protruding-garage-under-gable-roof.xml' => ['Cannot handle protruding garage and attic ridge running from front to back.'],
      'error-ambient-with-garage.xml' => ['Cannot handle garages with an ambient foundation type.'],
      'error-invalid-door-area.xml' => ['Door area cannot be negative.'],
      'error-invalid-window-aspect-ratio.xml' => ['Window aspect ratio must be greater than zero.'],
      'error-garage-too-wide.xml' => ['Garage is as wide as the single-family detached unit.'],
      'error-garage-too-deep.xml' => ['Garage is as deep as the single-family detached unit.'],
      'error-vented-attic-with-zero-floor-insulation.xml' => ["Element 'AssemblyEffectiveRValue': [facet 'minExclusive'] The value '0.0' must be greater than '0'."],
      'error-different-software-program.xml' => ["'Software Info: Program Used' cannot vary across dwelling units.",
                                                 "'Software Info: Program Version' cannot vary across dwelling units."],
      'error-different-simulation-control.xml' => ["'Simulation Control: Timestep' cannot vary across dwelling units.",
                                                   "'Simulation Control: Run Period' cannot vary across dwelling units.",
                                                   "'Simulation Control: Run Period Calendar Year' cannot vary across dwelling units.",
                                                   "'Simulation Control: Temperature Capacitance Multiplier' cannot vary across dwelling units."],
      'error-same-emissions-scenario-name.xml' => ["HPXML header already includes an emissions scenario named 'Emissions' with type 'CO2e'."],
      'error-same-utility-bill-scenario-name.xml' => ["HPXML header already includes a utility bill scenario named 'Bills'."],
      'error-could-not-find-epw-file.xml' => ['Could not find EPW file at']
    }

    expected_warnings = {
      'warning-non-electric-heat-pump-water-heater.xml' => ['Cannot model a heat pump water heater with non-electric fuel type.'],
      'warning-sfd-slab-non-zero-foundation-height.xml' => ["Foundation type of 'SlabOnGrade' cannot have a non-zero height. Assuming height is zero."],
      'warning-mf-bottom-slab-non-zero-foundation-height.xml' => ["Foundation type of 'SlabOnGrade' cannot have a non-zero height. Assuming height is zero."],
      'warning-slab-non-zero-foundation-height-above-grade.xml' => ['Specified a slab foundation type with a non-zero height above grade.'],
      'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml' => ['Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.'],
      'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml' => ['Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.'],
      'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml' => ['Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.'],
      'warning-vented-attic-with-floor-and-roof-insulation.xml' => ['Home with unconditioned attic type has both ceiling insulation and roof insulation.'],
      'warning-unvented-attic-with-floor-and-roof-insulation.xml' => ['Home with unconditioned attic type has both ceiling insulation and roof insulation.'],
      'warning-conditioned-basement-with-ceiling-insulation.xml' => ['Home with conditioned basement has floor insulation.'],
      'warning-conditioned-attic-with-floor-insulation.xml' => ['Home with conditioned attic has ceiling insulation.'],
      'warning-geothermal-loop-but-no-gshp.xml' => ['Specified an attached geothermal loop but home has no ground source heat pump.']
    }

    schema_path = File.join(File.dirname(__FILE__), '../..', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    schema_validator = XMLValidator.get_xml_validator(schema_path)

    puts "Generating #{hpxmls_files.size} HPXML files..."

    hpxmls_files.each_with_index do |(hpxml_file, parent), i|
      puts "[#{i + 1}/#{hpxmls_files.size}] Generating #{hpxml_file}..."

      begin
        all_hpxml_files = [hpxml_file]
        unless parent.nil?
          all_hpxml_files.unshift(parent)
        end
        while not parent.nil?
          next unless hpxmls_files.keys.include? parent

          unless hpxmls_files[parent].nil?
            all_hpxml_files.unshift(hpxmls_files[parent])
          end
          parent = hpxmls_files[parent]
        end

        args = {}
        all_hpxml_files.each do |f|
          _set_measure_argument_values(f, args)
        end

        measures_dir = File.join(File.dirname(__FILE__), '../..')
        measures = { 'BuildResidentialHPXML' => [args] }
        model = OpenStudio::Model::Model.new
        runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

        # Apply measure
        success = apply_measures(measures_dir, measures, runner, model)
        model.save(File.absolute_path(File.join(@output_path, hpxml_file.gsub('.xml', '.osm')))) if @model_save

        _test_measure(runner, expected_errors[hpxml_file], expected_warnings[hpxml_file])

        if not success
          runner.result.stepErrors.each do |s|
            puts "Error: #{s}"
          end

          next if hpxml_file.start_with?('error')

          flunk "Error: Did not successfully generate #{hpxml_file}."
        end
        hpxml_path = File.absolute_path(File.join(@output_path, hpxml_file))
        hpxml = HPXML.new(hpxml_path: hpxml_path)
        if hpxml.errors.size > 0
          puts hpxml.errors
          puts "\nError: Did not successfully validate #{hpxml_file}."
          exit!
        end
        hpxml.header.xml_generated_by = 'build_residential_hpxml_test.rb'
        hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs

        hpxml_doc = hpxml.to_doc()
        XMLHelper.write_file(hpxml_doc, hpxml_path)

        errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
        next unless errors.size > 0

        puts errors
        puts "\nError: Did not successfully validate #{hpxml_file}."
        exit!
      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace.join("\n")}"
        flunk "Error: Did not successfully generate #{hpxml_file}"
      end
    end

    # Check generated HPXML files
    hpxml = HPXML.new(hpxml_path: File.absolute_path(File.join(@output_path, 'extra-seasons-building-america.xml')))
    hvac_control = hpxml.buildings[0].hvac_controls[0]
    assert_equal(10, hvac_control.seasons_heating_begin_month)
    assert_equal(1, hvac_control.seasons_heating_begin_day)
    assert_equal(6, hvac_control.seasons_heating_end_month)
    assert_equal(30, hvac_control.seasons_heating_end_day)
    assert_equal(5, hvac_control.seasons_cooling_begin_month)
    assert_equal(1, hvac_control.seasons_cooling_begin_day)
    assert_equal(10, hvac_control.seasons_cooling_end_month)
    assert_equal(31, hvac_control.seasons_cooling_end_day)
  end

  private

  def _set_measure_argument_values(hpxml_file, args)
    args['hpxml_path'] = File.join(File.dirname(__FILE__), "extra_files/#{hpxml_file}")
    args['apply_defaults'] = true
    args['apply_validation'] = true

    # Base
    case hpxml_file
    when 'base-sfd.xml'
      args['simulation_control_timestep'] = 60
      args['weather_station_epw_filepath'] = 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
      args['site_type'] = HPXML::SiteTypeSuburban
      args['geometry_unit_type'] = HPXML::ResidentialTypeSFD
      args['geometry_unit_cfa'] = 2700.0
      args['geometry_unit_left_wall_is_adiabatic'] = false
      args['geometry_unit_right_wall_is_adiabatic'] = false
      args['geometry_unit_front_wall_is_adiabatic'] = false
      args['geometry_unit_back_wall_is_adiabatic'] = false
      args['geometry_unit_num_floors_above_grade'] = 1
      args['geometry_average_ceiling_height'] = 8.0
      args['geometry_unit_orientation'] = 180.0
      args['geometry_unit_aspect_ratio'] = 1.5
      args['geometry_garage_width'] = 0.0
      args['geometry_garage_depth'] = 20.0
      args['geometry_garage_protrusion'] = 0.0
      args['geometry_garage_position'] = Constants::PositionRight
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementConditioned
      args['geometry_foundation_height'] = 8.0
      args['geometry_foundation_height_above_grade'] = 1.0
      args['geometry_rim_joist_height'] = 9.25
      args['geometry_roof_type'] = Constants::RoofTypeGable
      args['geometry_roof_pitch'] = '6:12'
      args['geometry_attic_type'] = HPXML::AtticTypeUnvented
      args['geometry_eaves_depth'] = 0
      args['geometry_unit_num_bedrooms'] = 3
      args['geometry_unit_num_bathrooms'] = 2
      args['geometry_unit_num_occupants'] = 3
      args['floor_over_foundation_assembly_r'] = 0
      args['floor_over_garage_assembly_r'] = 0
      args['floor_type'] = HPXML::FloorTypeWoodFrame
      args['foundation_wall_thickness'] = 8.0
      args['foundation_wall_insulation_r'] = 8.9
      args['foundation_wall_insulation_distance_to_top'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = 8.0
      args['rim_joist_assembly_r'] = 23.0
      args['slab_perimeter_insulation_r'] = 0
      args['slab_perimeter_insulation_depth'] = 0
      args['slab_under_insulation_r'] = 0
      args['slab_under_insulation_width'] = 0
      args['slab_exterior_horizontal_insulation_r'] = 0
      args['slab_exterior_horizontal_insulation_width'] = 0
      args['slab_exterior_horizontal_insulation_depth_below_grade'] = 0
      args['slab_thickness'] = 4.0
      args['slab_carpet_fraction'] = 0.0
      args['slab_carpet_r'] = 0.0
      args['ceiling_assembly_r'] = 39.3
      args['roof_material_type'] = HPXML::RoofTypeAsphaltShingles
      args['roof_color'] = HPXML::ColorMedium
      args['roof_assembly_r'] = 2.3
      args['radiant_barrier_attic_location'] = Constants::None
      args['radiant_barrier_grade'] = 1
      args['neighbor_front_distance'] = 0
      args['neighbor_back_distance'] = 0
      args['neighbor_left_distance'] = 0
      args['neighbor_right_distance'] = 0
      args['wall_type'] = HPXML::WallTypeWoodStud
      args['wall_siding_type'] = HPXML::SidingTypeWood
      args['wall_color'] = HPXML::ColorMedium
      args['wall_assembly_r'] = 23
      args['window_front_wwr'] = 0
      args['window_back_wwr'] = 0
      args['window_left_wwr'] = 0
      args['window_right_wwr'] = 0
      args['window_area_front'] = 108.0
      args['window_area_back'] = 108.0
      args['window_area_left'] = 72.0
      args['window_area_right'] = 72.0
      args['window_aspect_ratio'] = 1.333
      args['window_fraction_operable'] = 0.67
      args['window_ufactor'] = 0.33
      args['window_shgc'] = 0.45
      args['window_interior_shading_winter'] = 0.85
      args['window_interior_shading_summer'] = 0.7
      args['overhangs_front_depth'] = 0
      args['overhangs_back_depth'] = 0
      args['overhangs_left_depth'] = 0
      args['overhangs_right_depth'] = 0
      args['overhangs_front_distance_to_top_of_window'] = 0
      args['overhangs_back_distance_to_top_of_window'] = 0
      args['overhangs_left_distance_to_top_of_window'] = 0
      args['overhangs_right_distance_to_top_of_window'] = 0
      args['overhangs_front_distance_to_bottom_of_window'] = 0
      args['overhangs_back_distance_to_bottom_of_window'] = 0
      args['overhangs_left_distance_to_bottom_of_window'] = 0
      args['overhangs_right_distance_to_bottom_of_window'] = 0
      args['skylight_area_front'] = 0
      args['skylight_area_back'] = 0
      args['skylight_area_left'] = 0
      args['skylight_area_right'] = 0
      args['skylight_ufactor'] = 0.33
      args['skylight_shgc'] = 0.45
      args['door_area'] = 40.0
      args['door_rvalue'] = 4.4
      args['air_leakage_units'] = HPXML::UnitsACH
      args['air_leakage_house_pressure'] = 50
      args['air_leakage_value'] = 3
      args['heating_system_type'] = HPXML::HVACTypeFurnace
      args['heating_system_fuel'] = HPXML::FuelTypeNaturalGas
      args['heating_system_heating_efficiency'] = 0.92
      args['heating_system_heating_capacity'] = 36000.0
      args['heating_system_fraction_heat_load_served'] = 1
      args['cooling_system_type'] = HPXML::HVACTypeCentralAirConditioner
      args['cooling_system_cooling_efficiency_type'] = HPXML::UnitsSEER
      args['cooling_system_cooling_efficiency'] = 13.0
      args['cooling_system_compressor_type'] = HPXML::HVACCompressorTypeSingleStage
      args['cooling_system_cooling_capacity'] = 24000.0
      args['cooling_system_fraction_cool_load_served'] = 1
      args['cooling_system_is_ducted'] = false
      args['heat_pump_type'] = Constants::None
      args['heat_pump_heating_efficiency_type'] = HPXML::UnitsHSPF
      args['heat_pump_heating_efficiency'] = 7.7
      args['heat_pump_cooling_efficiency_type'] = HPXML::UnitsSEER
      args['heat_pump_cooling_efficiency'] = 13.0
      args['heat_pump_compressor_type'] = HPXML::HVACCompressorTypeSingleStage
      args['heat_pump_heating_capacity'] = 36000.0
      args['heat_pump_cooling_capacity'] = 36000.0
      args['heat_pump_fraction_heat_load_served'] = 1
      args['heat_pump_fraction_cool_load_served'] = 1
      args['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
      args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
      args['heat_pump_backup_heating_efficiency'] = 1
      args['heat_pump_backup_heating_capacity'] = 36000.0
      args['geothermal_loop_configuration'] = Constants::None
      args['hvac_control_heating_weekday_setpoint'] = 68
      args['hvac_control_heating_weekend_setpoint'] = 68
      args['hvac_control_cooling_weekday_setpoint'] = 78
      args['hvac_control_cooling_weekend_setpoint'] = 78
      args['ducts_leakage_units'] = HPXML::UnitsCFM25
      args['ducts_supply_leakage_to_outside_value'] = 75.0
      args['ducts_return_leakage_to_outside_value'] = 25.0
      args['ducts_supply_insulation_r'] = 4.0
      args['ducts_return_insulation_r'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationAtticUnvented
      args['ducts_return_location'] = HPXML::LocationAtticUnvented
      args['ducts_supply_surface_area'] = 150.0
      args['ducts_return_surface_area'] = 50.0
      args['ducts_number_of_return_registers'] = 2
      args['heating_system_2_type'] = Constants::None
      args['heating_system_2_fuel'] = HPXML::FuelTypeElectricity
      args['heating_system_2_heating_efficiency'] = 1.0
      args['heating_system_2_fraction_heat_load_served'] = 0.25
      args['mech_vent_fan_type'] = Constants::None
      args['mech_vent_flow_rate'] = 110
      args['mech_vent_hours_in_operation'] = 24
      args['mech_vent_recovery_efficiency_type'] = 'Unadjusted'
      args['mech_vent_total_recovery_efficiency'] = 0.48
      args['mech_vent_sensible_recovery_efficiency'] = 0.72
      args['mech_vent_fan_power'] = 30
      args['mech_vent_num_units_served'] = 1
      args['mech_vent_2_fan_type'] = Constants::None
      args['mech_vent_2_flow_rate'] = 110
      args['mech_vent_2_hours_in_operation'] = 24
      args['mech_vent_2_recovery_efficiency_type'] = 'Unadjusted'
      args['mech_vent_2_total_recovery_efficiency'] = 0.48
      args['mech_vent_2_sensible_recovery_efficiency'] = 0.72
      args['mech_vent_2_fan_power'] = 30
      args['kitchen_fans_quantity'] = 0
      args['bathroom_fans_quantity'] = 0
      args['whole_house_fan_present'] = false
      args['water_heater_type'] = HPXML::WaterHeaterTypeStorage
      args['water_heater_fuel_type'] = HPXML::FuelTypeElectricity
      args['water_heater_location'] = HPXML::LocationConditionedSpace
      args['water_heater_tank_volume'] = 40
      args['water_heater_efficiency_type'] = 'EnergyFactor'
      args['water_heater_efficiency'] = 0.95
      args['water_heater_recovery_efficiency'] = 0.76
      args['water_heater_heating_capacity'] = 18767
      args['water_heater_standby_loss'] = 0
      args['water_heater_jacket_rvalue'] = 0
      args['water_heater_setpoint_temperature'] = 125
      args['water_heater_num_bedrooms_served'] = 3
      args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeStandard
      args['hot_water_distribution_standard_piping_length'] = 50
      args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecircControlTypeNone
      args['hot_water_distribution_recirc_piping_length'] = 50
      args['hot_water_distribution_recirc_branch_piping_length'] = 50
      args['hot_water_distribution_recirc_pump_power'] = 50
      args['hot_water_distribution_pipe_r'] = 0.0
      args['dwhr_facilities_connected'] = Constants::None
      args['dwhr_equal_flow'] = true
      args['dwhr_efficiency'] = 0.55
      args['water_fixtures_shower_low_flow'] = true
      args['water_fixtures_sink_low_flow'] = false
      args['solar_thermal_system_type'] = Constants::None
      args['solar_thermal_collector_area'] = 40.0
      args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeDirect
      args['solar_thermal_collector_type'] = HPXML::SolarThermalCollectorTypeEvacuatedTube
      args['solar_thermal_collector_azimuth'] = 180
      args['solar_thermal_collector_tilt'] = 20
      args['solar_thermal_collector_rated_optical_efficiency'] = 0.5
      args['solar_thermal_collector_rated_thermal_losses'] = 0.2799
      args['solar_thermal_solar_fraction'] = 0
      args['pv_system_present'] = false
      args['pv_system_array_azimuth'] = 180
      args['pv_system_array_tilt'] = 20
      args['pv_system_max_power_output'] = 4000
      args['pv_system_2_present'] = false
      args['pv_system_2_array_azimuth'] = 180
      args['pv_system_2_array_tilt'] = 20
      args['pv_system_2_max_power_output'] = 4000
      args['battery_present'] = false
      args['lighting_present'] = true
      args['lighting_interior_fraction_cfl'] = 0.4
      args['lighting_interior_fraction_lfl'] = 0.1
      args['lighting_interior_fraction_led'] = 0.25
      args['lighting_exterior_fraction_cfl'] = 0.4
      args['lighting_exterior_fraction_lfl'] = 0.1
      args['lighting_exterior_fraction_led'] = 0.25
      args['lighting_garage_fraction_cfl'] = 0.4
      args['lighting_garage_fraction_lfl'] = 0.1
      args['lighting_garage_fraction_led'] = 0.25
      args['holiday_lighting_present'] = false
      args['dehumidifier_type'] = Constants::None
      args['dehumidifier_efficiency_type'] = 'EnergyFactor'
      args['dehumidifier_efficiency'] = 1.8
      args['dehumidifier_capacity'] = 40
      args['dehumidifier_rh_setpoint'] = 0.5
      args['dehumidifier_fraction_dehumidification_load_served'] = 1
      args['clothes_washer_present'] = true
      args['clothes_washer_location'] = HPXML::LocationConditionedSpace
      args['clothes_washer_efficiency_type'] = 'IntegratedModifiedEnergyFactor'
      args['clothes_washer_efficiency'] = 1.21
      args['clothes_washer_rated_annual_kwh'] = 380.0
      args['clothes_washer_label_electric_rate'] = 0.12
      args['clothes_washer_label_gas_rate'] = 1.09
      args['clothes_washer_label_annual_gas_cost'] = 27.0
      args['clothes_washer_label_usage'] = 6.0
      args['clothes_washer_capacity'] = 3.2
      args['clothes_dryer_present'] = true
      args['clothes_dryer_location'] = HPXML::LocationConditionedSpace
      args['clothes_dryer_fuel_type'] = HPXML::FuelTypeElectricity
      args['clothes_dryer_efficiency_type'] = 'CombinedEnergyFactor'
      args['clothes_dryer_efficiency'] = 3.73
      args['dishwasher_present'] = true
      args['dishwasher_location'] = HPXML::LocationConditionedSpace
      args['dishwasher_efficiency_type'] = 'RatedAnnualkWh'
      args['dishwasher_efficiency'] = 307
      args['dishwasher_label_electric_rate'] = 0.12
      args['dishwasher_label_gas_rate'] = 1.09
      args['dishwasher_label_annual_gas_cost'] = 22.32
      args['dishwasher_label_usage'] = 4.0
      args['dishwasher_place_setting_capacity'] = 12
      args['refrigerator_present'] = true
      args['refrigerator_location'] = HPXML::LocationConditionedSpace
      args['refrigerator_rated_annual_kwh'] = 650.0
      args['extra_refrigerator_present'] = false
      args['freezer_present'] = false
      args['cooking_range_oven_present'] = true
      args['cooking_range_oven_location'] = HPXML::LocationConditionedSpace
      args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeElectricity
      args['cooking_range_oven_is_induction'] = false
      args['cooking_range_oven_is_convection'] = false
      args['ceiling_fan_present'] = false
      args['misc_plug_loads_television_present'] = true
      args['misc_plug_loads_television_annual_kwh'] = 620.0
      args['misc_plug_loads_other_annual_kwh'] = 2457.0
      args['misc_plug_loads_other_frac_sensible'] = 0.855
      args['misc_plug_loads_other_frac_latent'] = 0.045
      args['misc_plug_loads_well_pump_present'] = false
      args['misc_plug_loads_vehicle_present'] = false
      args['misc_fuel_loads_grill_present'] = false
      args['misc_fuel_loads_grill_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['misc_fuel_loads_lighting_present'] = false
      args['misc_fuel_loads_lighting_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['misc_fuel_loads_fireplace_present'] = false
      args['misc_fuel_loads_fireplace_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['pool_present'] = false
      args['pool_heater_type'] = HPXML::HeaterTypeElectricResistance
      args['permanent_spa_present'] = false
      args['permanent_spa_heater_type'] = HPXML::HeaterTypeElectricResistance
    when 'base-sfd2.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfd.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    when 'base-sfa.xml'
      args['geometry_unit_type'] = HPXML::ResidentialTypeSFA
      args['geometry_unit_cfa'] = 1800.0
      args['geometry_building_num_units'] = 3
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['window_front_wwr'] = 0.18
      args['window_back_wwr'] = 0.18
      args['window_left_wwr'] = 0.18
      args['window_right_wwr'] = 0.18
      args['window_area_front'] = 0
      args['window_area_back'] = 0
      args['window_area_left'] = 0
      args['window_area_right'] = 0
      args['air_leakage_type'] = HPXML::InfiltrationTypeUnitTotal
    when 'base-sfa2.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfa.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    when 'base-sfa3.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfa2.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    when 'base-mf.xml'
      args['geometry_unit_type'] = HPXML::ResidentialTypeApartment
      args['geometry_unit_cfa'] = 900.0
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_building_num_units'] = 6
      args['window_front_wwr'] = 0.18
      args['window_back_wwr'] = 0.18
      args['window_left_wwr'] = 0.18
      args['window_right_wwr'] = 0.18
      args['window_area_front'] = 0
      args['window_area_back'] = 0
      args['window_area_left'] = 0
      args['window_area_right'] = 0
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationConditionedSpace
      args['ducts_return_location'] = HPXML::LocationConditionedSpace
      args['ducts_supply_insulation_r'] = 0.0
      args['ducts_return_insulation_r'] = 0.0
      args['ducts_number_of_return_registers'] = 1
      args['door_area'] = 20.0
      args['air_leakage_type'] = HPXML::InfiltrationTypeUnitTotal
    when 'base-mf2.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-mf.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    when 'base-mf3.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-mf2.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    when 'base-mf4.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-mf3.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    when 'base-sfd-header.xml'
      args['software_info_program_used'] = 'Program'
      args['software_info_program_version'] = '1'
      args['schedules_unavailable_period_types'] = 'Vacancy, Power Outage'
      args['schedules_unavailable_period_dates'] = 'Jan 2 - Jan 5, Feb 10 - Feb 12'
      args['schedules_unavailable_period_window_natvent_availabilities'] = "#{HPXML::ScheduleUnavailable}, #{HPXML::ScheduleAvailable}"
      args['simulation_control_run_period'] = 'Jan 1 - Dec 31'
      args['simulation_control_run_period_calendar_year'] = 2007
      args['simulation_control_temperature_capacitance_multiplier'] = 1.0
      args['emissions_scenario_names'] = 'Emissions'
      args['emissions_types'] = 'CO2e'
      args['emissions_electricity_units'] = 'kg/MWh'
      args['emissions_electricity_values_or_filepaths'] = '1'
      args['emissions_fossil_fuel_units'] = 'kg/MBtu'
      args['emissions_natural_gas_values'] = '2'
      args['utility_bill_scenario_names'] = 'Bills'
    when 'base-sfd-header-no-duplicates.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfd-header.xml')
      args['whole_sfa_or_mf_building_sim'] = true
    end

    # Extras
    case hpxml_file
    when 'extra-auto.xml'
      args.delete('geometry_unit_num_occupants')
      args.delete('ducts_supply_location')
      args.delete('ducts_return_location')
      args.delete('ducts_supply_surface_area')
      args.delete('ducts_return_surface_area')
      args.delete('water_heater_location')
      args.delete('water_heater_tank_volume')
      args.delete('hot_water_distribution_standard_piping_length')
      args.delete('clothes_washer_location')
      args.delete('clothes_dryer_location')
      args.delete('refrigerator_location')
    when 'extra-auto-duct-locations.xml'
      args['ducts_supply_location'] = HPXML::LocationAtticUnvented
      args['ducts_return_location'] = HPXML::LocationAtticUnvented
    when 'extra-pv-roofpitch.xml'
      args['pv_system_module_type'] = HPXML::PVModuleTypeStandard
      args['pv_system_2_module_type'] = HPXML::PVModuleTypeStandard
      args['pv_system_array_tilt'] = 'roofpitch'
      args['pv_system_2_array_tilt'] = 'roofpitch+15'
    when 'extra-dhw-solar-latitude.xml'
      args['solar_thermal_system_type'] = HPXML::SolarThermalSystemTypeHotWater
      args['solar_thermal_collector_tilt'] = 'Latitude-15'
    when 'extra-second-refrigerator.xml'
      args['extra_refrigerator_location'] = HPXML::LocationConditionedSpace
    when 'extra-second-heating-system-portable-heater-to-heating-system.xml'
      args['heating_system_fuel'] = HPXML::FuelTypeElectricity
      args['heating_system_heating_capacity'] = 48000.0
      args['heating_system_fraction_heat_load_served'] = 0.75
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationConditionedSpace
      args['ducts_return_location'] = HPXML::LocationConditionedSpace
      args['heating_system_2_type'] = HPXML::HVACTypeSpaceHeater
      args['heating_system_2_heating_capacity'] = 16000.0
    when 'extra-second-heating-system-fireplace-to-heating-system.xml'
      args['heating_system_type'] = HPXML::HVACTypeElectricResistance
      args['heating_system_fuel'] = HPXML::FuelTypeElectricity
      args['heating_system_heating_efficiency'] = 1.0
      args['heating_system_heating_capacity'] = 48000.0
      args['heating_system_fraction_heat_load_served'] = 0.75
      args['cooling_system_type'] = Constants::None
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
      args['heating_system_2_heating_capacity'] = 16000.0
    when 'extra-second-heating-system-boiler-to-heating-system.xml'
      args['heating_system_type'] = HPXML::HVACTypeBoiler
      args['heating_system_fraction_heat_load_served'] = 0.75
      args['heating_system_2_type'] = HPXML::HVACTypeBoiler
    when 'extra-second-heating-system-portable-heater-to-heat-pump.xml'
      args['heating_system_type'] = Constants::None
      args['cooling_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
      args['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
      args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
      args['heat_pump_heating_capacity'] = 48000.0
      args['heat_pump_fraction_heat_load_served'] = 0.75
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationConditionedSpace
      args['ducts_return_location'] = HPXML::LocationConditionedSpace
      args['heating_system_2_type'] = HPXML::HVACTypeSpaceHeater
      args['heating_system_2_heating_capacity'] = 16000.0
    when 'extra-second-heating-system-fireplace-to-heat-pump.xml'
      args['heating_system_type'] = Constants::None
      args['cooling_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpMiniSplit
      args['heat_pump_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
      args['heat_pump_heating_efficiency'] = 10.0
      args['heat_pump_cooling_efficiency'] = 19.0
      args['heat_pump_heating_capacity'] = 48000.0
      args['heat_pump_is_ducted'] = true
      args['heat_pump_fraction_heat_load_served'] = 0.75
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
      args['heating_system_2_heating_capacity'] = 16000.0
    when 'extra-second-heating-system-boiler-to-heat-pump.xml'
      args['heating_system_type'] = Constants::None
      args['cooling_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpGroundToAir
      args['heat_pump_heating_efficiency_type'] = HPXML::UnitsCOP
      args['heat_pump_heating_efficiency'] = 3.6
      args['heat_pump_cooling_efficiency_type'] = HPXML::UnitsEER
      args['heat_pump_cooling_efficiency'] = 16.6
      args['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
      args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
      args['heat_pump_fraction_heat_load_served'] = 0.75
      args['heating_system_2_type'] = HPXML::HVACTypeBoiler
    when 'extra-enclosure-windows-shading.xml'
      args['window_interior_shading_winter'] = 0.99
      args['window_interior_shading_summer'] = 0.01
      args['window_exterior_shading_winter'] = 0.9
      args['window_exterior_shading_summer'] = 0.1
    when 'extra-enclosure-garage-partially-protruded.xml'
      args['geometry_garage_width'] = 12
      args['geometry_garage_protrusion'] = 0.5
    when 'extra-enclosure-garage-atticroof-conditioned.xml'
      args['geometry_garage_width'] = 30.0
      args['geometry_garage_protrusion'] = 1.0
      args['window_area_front'] = 12.0
      args['window_aspect_ratio'] = 5.0 / 1.5
      args['geometry_unit_cfa'] = 4500.0
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['floor_over_garage_assembly_r'] = 39.3
      args['ducts_supply_location'] = HPXML::LocationGarage
      args['ducts_return_location'] = HPXML::LocationGarage
    when 'extra-enclosure-atticroof-conditioned-eaves-gable.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['geometry_foundation_height_above_grade'] = 0.0
      args.delete('foundation_wall_insulation_distance_to_bottom')
      args['geometry_unit_cfa'] = 4500.0
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['geometry_eaves_depth'] = 2
      args['ducts_supply_location'] = HPXML::LocationUnderSlab
      args['ducts_return_location'] = HPXML::LocationUnderSlab
    when 'extra-enclosure-atticroof-conditioned-eaves-hip.xml'
      args['geometry_roof_type'] = Constants::RoofTypeHip
    when 'extra-gas-pool-heater-with-zero-kwh.xml'
      args['pool_present'] = true
      args['pool_heater_type'] = HPXML::HeaterTypeGas
      args['pool_heater_annual_kwh'] = 0
    when 'extra-gas-hot-tub-heater-with-zero-kwh.xml'
      args['permanent_spa_present'] = true
      args['permanent_spa_heater_type'] = HPXML::HeaterTypeGas
      args['permanent_spa_heater_annual_kwh'] = 0
    when 'extra-no-rim-joists.xml'
      args.delete('geometry_rim_joist_height')
      args.delete('rim_joist_assembly_r')
    when 'extra-iecc-zone-different-than-epw.xml'
      args['site_iecc_zone'] = '6B'
    when 'extra-state-code-different-than-epw.xml'
      args['site_state_code'] = 'WY'
    when 'extra-time-zone-different-than-epw.xml'
      args['site_time_zone_utc_offset'] = '-6'
    when 'extra-emissions-fossil-fuel-factors.xml'
      args['emissions_scenario_names'] = 'Scenario1, Scenario2'
      args['emissions_types'] = 'CO2e, SO2'
      args['emissions_electricity_units'] = "#{HPXML::EmissionsScenario::UnitsKgPerMWh}, #{HPXML::EmissionsScenario::UnitsLbPerMWh}"
      args['emissions_electricity_values_or_filepaths'] = '392.6, 0.384'
      args['emissions_fossil_fuel_units'] = "#{HPXML::EmissionsScenario::UnitsLbPerMBtu}, #{HPXML::EmissionsScenario::UnitsLbPerMBtu}"
      args['emissions_natural_gas_values'] = '117.6, 0.0006'
      args['emissions_propane_values'] = '136.6, 0.0002'
      args['emissions_fuel_oil_values'] = '161.0, 0.0015'
      args['emissions_coal_values'] = '211.1, 0.0020'
      args['emissions_wood_values'] = '200.0, 0.0025'
    when 'extra-bills-fossil-fuel-rates.xml'
      args['utility_bill_scenario_names'] = 'Scenario1, Scenario2'
      args['utility_bill_propane_fixed_charges'] = '1, 2'
      args['utility_bill_propane_marginal_rates'] = '3, 4'
      args['utility_bill_fuel_oil_fixed_charges'] = '5, 6'
      args['utility_bill_fuel_oil_marginal_rates'] = '6, 7'
      args['utility_bill_coal_fixed_charges'] = '8, 9'
      args['utility_bill_coal_marginal_rates'] = '10, 11'
      args['utility_bill_wood_fixed_charges'] = '12, 13'
      args['utility_bill_wood_marginal_rates'] = '14, 15'
      args['utility_bill_wood_pellets_fixed_charges'] = '16, 17'
      args['utility_bill_wood_pellets_marginal_rates'] = '18, 19'
    when 'extra-seasons-building-america.xml'
      args['hvac_control_heating_season_period'] = Constants::BuildingAmerica
      args['hvac_control_cooling_season_period'] = Constants::BuildingAmerica
    when 'extra-ducts-crawlspace.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4
      args['ducts_supply_location'] = HPXML::LocationCrawlspace
      args['ducts_return_location'] = HPXML::LocationCrawlspace
    when 'extra-ducts-attic.xml'
      args['ducts_supply_location'] = HPXML::LocationAttic
      args['ducts_return_location'] = HPXML::LocationAttic
    when 'extra-water-heater-crawlspace.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4
      args['water_heater_location'] = HPXML::LocationCrawlspace
    when 'extra-water-heater-attic.xml'
      args['water_heater_location'] = HPXML::LocationAttic
    when 'extra-battery-crawlspace.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4
      args['battery_present'] = true
      args['battery_location'] = HPXML::LocationCrawlspace
    when 'extra-battery-attic.xml'
      args['battery_present'] = true
      args['battery_location'] = HPXML::LocationAttic
    when 'extra-vehicle-ev.xml'
      args['vehicle_type'] = HPXML::VehicleTypeBEV
      args['ev_charger_present'] = true
    when 'extra-two-batteries.xml'
      args['vehicle_type'] = HPXML::VehicleTypeBEV
      args['battery_present'] = true
      args['battery_location'] = HPXML::LocationAttic
    when 'extra-detailed-performance-autosize-cooling-system.xml'
      args['cooling_system_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
      args.delete('cooling_system_cooling_capacity')
      args['hvac_perf_data_capacity_type'] = 'Normalized capacity fractions'
      args['hvac_perf_data_cooling_outdoor_temperatures'] = '125.0, 95.0, 82.0'
      args['hvac_perf_data_cooling_min_speed_capacities'] = '0.267, 0.333, 0.368'
      args['hvac_perf_data_cooling_nom_speed_capacities'] = ', 1.000'
      args['hvac_perf_data_cooling_max_speed_capacities'] = '0.847, 1.017, 1.090'
      args['hvac_perf_data_cooling_min_speed_cops'] = '1.918, 3.870, 5.860'
      args['hvac_perf_data_cooling_nom_speed_cops'] = ', 3.236'
      args['hvac_perf_data_cooling_max_speed_cops'] = '2.017, 3.220, 4.140'
    when 'extra-detailed-performance-autosize-heat-pump.xml'
      args['heating_system_type'] = Constants::None
      args['cooling_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
      args['heat_pump_heating_efficiency'] = 10.0
      args['heat_pump_cooling_efficiency'] = 17.25
      args['heat_pump_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
      args.delete('heat_pump_heating_capacity')
      args.delete('heat_pump_cooling_capacity')
      args['hvac_perf_data_capacity_type'] = 'Normalized capacity fractions'
      args['hvac_perf_data_heating_outdoor_temperatures'] = '47.0, 17.0, 5.0'
      args['hvac_perf_data_heating_min_speed_capacities'] = '0.28, 0.12, 0.05'
      args['hvac_perf_data_heating_nom_speed_capacities'] = '1.0, 0.5, 0.3'
      args['hvac_perf_data_heating_max_speed_capacities'] = '1.2, 0.69, 0.55'
      args['hvac_perf_data_heating_min_speed_cops'] = '4.73, 1.84, 0.81'
      args['hvac_perf_data_heating_nom_speed_cops'] = '4.0, 3.2, 1.8'
      args['hvac_perf_data_heating_max_speed_cops'] = '3.44, 2.66, 2.28'
      args['hvac_perf_data_cooling_outdoor_temperatures'] = '95.0, 82.0'
      args['hvac_perf_data_cooling_min_speed_capacities'] = '0.325, 0.37'
      args['hvac_perf_data_cooling_nom_speed_capacities'] = '1.0, 0.6'
      args['hvac_perf_data_cooling_max_speed_capacities'] = '1.11, 1.5'
      args['hvac_perf_data_cooling_min_speed_cops'] = '4.47, 6.34'
      args['hvac_perf_data_cooling_nom_speed_cops'] = '3.8, 5.0'
      args['hvac_perf_data_cooling_max_speed_cops'] = '2.71, 3.53'
    when 'extra-detailed-performance-autosize-heat-pump2.xml'
      args['hvac_perf_data_heating_outdoor_temperatures'] = '47.0, 17.0, 5.0, -15.0'
      args['hvac_perf_data_heating_min_speed_capacities'] = '0.308, 0.353, 0.371, 0.331'
      args['hvac_perf_data_heating_nom_speed_capacities'] = '1.000, 0.745'
      args['hvac_perf_data_heating_max_speed_capacities'] = '1.028, 0.766, 0.688, 0.507'
      args['hvac_perf_data_heating_min_speed_cops'] = '4.390, 2.550, 2.050, 1.660'
      args['hvac_perf_data_heating_nom_speed_cops'] = '3.410, 2.341'
      args['hvac_perf_data_heating_max_speed_cops'] = '3.370, 2.330, 1.980, 1.490'
      args['hvac_perf_data_cooling_outdoor_temperatures'] = '125.0, 95.0, 82.0'
      args['hvac_perf_data_cooling_min_speed_capacities'] = '0.267, 0.333, 0.368'
      args['hvac_perf_data_cooling_nom_speed_capacities'] = ', 1.000'
      args['hvac_perf_data_cooling_max_speed_capacities'] = '0.847, 1.017, 1.090'
      args['hvac_perf_data_cooling_min_speed_cops'] = '1.918, 3.870, 5.860'
      args['hvac_perf_data_cooling_nom_speed_cops'] = ', 3.236'
      args['hvac_perf_data_cooling_max_speed_cops'] = '2.017, 3.220, 4.140'
    when 'extra-power-outage-periods.xml'
      args['schedules_unavailable_period_types'] = 'Power Outage, Power Outage'
      args['schedules_unavailable_period_dates'] = 'Jan 1 - Jan 5, Jan 7 - Jan 9'
    when 'extra-sfa-atticroof-flat.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeFlatRoof
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationBasementConditioned
      args['ducts_return_location'] = HPXML::LocationBasementConditioned
    when 'extra-sfa-atticroof-conditioned-eaves-gable.xml'
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['geometry_eaves_depth'] = 2
      args['ducts_supply_location'] = HPXML::LocationConditionedSpace
      args['ducts_return_location'] = HPXML::LocationConditionedSpace
    when 'extra-sfa-atticroof-conditioned-eaves-hip.xml'
      args['geometry_roof_type'] = Constants::RoofTypeHip
    when 'extra-mf-eaves.xml'
      args['geometry_eaves_depth'] = 2
    when 'extra-sfa-slab.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['geometry_foundation_height_above_grade'] = 0.0
      args.delete('foundation_wall_insulation_distance_to_bottom')
    when 'extra-sfa-vented-crawlspace.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    when 'extra-sfa-unvented-crawlspace.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    when 'extra-sfa-conditioned-crawlspace.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceConditioned
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 2.1
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    when 'extra-sfa-unconditioned-basement.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_r'] = 0
      args['foundation_wall_insulation_distance_to_bottom'] = 0.0
    when 'extra-sfa-ambient.xml'
      args['geometry_unit_cfa'] = 900.0
      args['geometry_foundation_type'] = HPXML::FoundationTypeAmbient
      args.delete('geometry_rim_joist_height')
      args['floor_over_foundation_assembly_r'] = 18.7
      args.delete('rim_joist_assembly_r')
      args['misc_plug_loads_other_annual_kwh'] = 1228.5
    when 'extra-sfa-rear-units.xml'
      args['geometry_building_num_units'] = 4
    when 'extra-sfa-exterior-corridor.xml'
      args['geometry_building_num_units'] = 4
    when 'extra-sfa-slab-middle.xml', 'extra-sfa-vented-crawlspace-middle.xml',
         'extra-sfa-unvented-crawlspace-middle.xml', 'extra-sfa-unconditioned-basement-middle.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
    when 'extra-sfa-slab-right.xml', 'extra-sfa-vented-crawlspace-right.xml',
         'extra-sfa-unvented-crawlspace-right.xml', 'extra-sfa-unconditioned-basement-right.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
    when 'extra-mf-atticroof-flat.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeFlatRoof
    when 'extra-mf-atticroof-vented.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeVented
    when 'extra-mf-slab.xml'
      args['geometry_building_num_units'] = 18
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['geometry_foundation_height_above_grade'] = 0.0
      args.delete('foundation_wall_insulation_distance_to_bottom')
    when 'extra-mf-vented-crawlspace.xml'
      args['geometry_building_num_units'] = 18
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    when 'extra-mf-unvented-crawlspace.xml'
      args['geometry_building_num_units'] = 18
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    when 'extra-mf-ambient.xml'
      args['geometry_unit_cfa'] = 450.0
      args['geometry_foundation_type'] = HPXML::FoundationTypeAmbient
      args.delete('geometry_rim_joist_height')
      args['floor_over_foundation_assembly_r'] = 18.7
      args.delete('rim_joist_assembly_r')
      args['misc_plug_loads_other_annual_kwh'] = 1228.5
    when 'extra-mf-rear-units.xml'
      args['geometry_building_num_units'] = 18
    when 'extra-mf-exterior-corridor.xml'
      args['geometry_building_num_units'] = 18
    when 'extra-mf-slab-left-bottom.xml', 'extra-mf-vented-crawlspace-left-bottom.xml',
         'extra-mf-unvented-crawlspace-left-bottom.xml'
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    when 'extra-mf-slab-left-middle.xml', 'extra-mf-vented-crawlspace-left-middle.xml',
         'extra-mf-unvented-crawlspace-left-middle.xml'
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'extra-mf-slab-left-top.xml', 'extra-mf-vented-crawlspace-left-top.xml',
         'extra-mf-unvented-crawlspace-left-top.xml'
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'extra-mf-slab-middle-bottom.xml', 'extra-mf-vented-crawlspace-middle-bottom.xml',
         'extra-mf-unvented-crawlspace-middle-bottom.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    when 'extra-mf-slab-middle-middle.xml', 'extra-mf-vented-crawlspace-middle-middle.xml',
         'extra-mf-unvented-crawlspace-middle-middle.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'extra-mf-slab-middle-top.xml', 'extra-mf-vented-crawlspace-middle-top.xml',
         'extra-mf-unvented-crawlspace-middle-top.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'extra-mf-slab-right-bottom.xml', 'extra-mf-vented-crawlspace-right-bottom.xml',
         'extra-mf-unvented-crawlspace-right-bottom.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    when 'extra-mf-slab-right-middle.xml', 'extra-mf-vented-crawlspace-right-middle.xml',
         'extra-mf-unvented-crawlspace-right-middle.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'extra-mf-slab-right-top.xml', 'extra-mf-vented-crawlspace-right-top.xml',
         'extra-mf-unvented-crawlspace-right-top.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'extra-mf-slab-rear-units.xml',
         'extra-mf-vented-crawlspace-rear-units.xml',
         'extra-mf-unvented-crawlspace-rear-units.xml',
         'extra-mf-slab-left-bottom-rear-units.xml',
         'extra-mf-slab-left-middle-rear-units.xml',
         'extra-mf-slab-left-top-rear-units.xml',
         'extra-mf-slab-middle-bottom-rear-units.xml',
         'extra-mf-slab-middle-middle-rear-units.xml',
         'extra-mf-slab-middle-top-rear-units.xml',
         'extra-mf-slab-right-bottom-rear-units.xml',
         'extra-mf-slab-right-middle-rear-units.xml',
          'extra-mf-slab-right-top-rear-units.xml',
          'extra-mf-vented-crawlspace-left-bottom-rear-units.xml',
          'extra-mf-vented-crawlspace-left-middle-rear-units.xml',
          'extra-mf-vented-crawlspace-left-top-rear-units.xml',
          'extra-mf-vented-crawlspace-middle-bottom-rear-units.xml',
          'extra-mf-vented-crawlspace-middle-middle-rear-units.xml',
          'extra-mf-vented-crawlspace-middle-top-rear-units.xml',
          'extra-mf-vented-crawlspace-right-bottom-rear-units.xml',
          'extra-mf-vented-crawlspace-right-middle-rear-units.xml',
          'extra-mf-vented-crawlspace-right-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-bottom-rear-units.xml',
          'extra-mf-unvented-crawlspace-left-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-top-rear-units.xml'
      args['geometry_unit_front_wall_is_adiabatic'] = true
    end

    # Error
    case hpxml_file
    when 'error-heating-system-and-heat-pump.xml'
      args['cooling_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    when 'error-cooling-system-and-heat-pump.xml'
      args['heating_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    when 'error-sfd-conditioned-basement-zero-foundation-height.xml'
      args['geometry_foundation_height'] = 0.0
      args.delete('foundation_wall_insulation_distance_to_bottom')
    when 'error-sfd-adiabatic-walls.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
    when 'error-mf-conditioned-basement'
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementConditioned
    when 'error-mf-conditioned-crawlspace'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceConditioned
    when 'error-mf-bottom-crawlspace-zero-foundation-height.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 0.0
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args.delete('foundation_wall_insulation_distance_to_bottom')
    when 'error-second-heating-system-but-no-primary-heating.xml'
      args['heating_system_type'] = Constants::None
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
    when 'error-second-heating-system-ducted-with-ducted-primary-heating.xml'
      args['heating_system_type'] = Constants::None
      args['cooling_system_type'] = Constants::None
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpMiniSplit
      args['heat_pump_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
      args['heat_pump_is_ducted'] = true
      args['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
      args['heating_system_2_type'] = HPXML::HVACTypeFurnace
    when 'error-sfa-no-building-num-units.xml'
      args.delete('geometry_building_num_units')
    when 'error-sfa-above-apartment.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    when 'error-sfa-below-apartment.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    when 'error-sfa-all-adiabatic-walls.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_unit_front_wall_is_adiabatic'] = true
      args['geometry_unit_back_wall_is_adiabatic'] = true
    when 'error-mf-no-building-num-units.xml'
      args.delete('geometry_building_num_units')
    when 'error-mf-all-adiabatic-walls.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_unit_front_wall_is_adiabatic'] = true
      args['geometry_unit_back_wall_is_adiabatic'] = true
    when 'error-mf-two-stories.xml'
      args['geometry_unit_num_floors_above_grade'] = 2
    when 'error-mf-conditioned-attic.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
    when 'error-dhw-indirect-without-boiler.xml'
      args['water_heater_type'] = HPXML::WaterHeaterTypeCombiStorage
    when 'error-conditioned-attic-with-one-floor-above-grade.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['ceiling_assembly_r'] = 0.0
    when 'error-sfd-with-shared-system.xml'
      args['heating_system_type'] = "Shared #{HPXML::HVACTypeBoiler} w/ Baseboard"
    when 'error-rim-joist-height-but-no-assembly-r.xml'
      args.delete('rim_joist_assembly_r')
    when 'error-rim-joist-assembly-r-but-no-height.xml'
      args.delete('geometry_rim_joist_height')
    when 'error-unavailable-period-args-not-all-specified'
      args['schedules_unavailable_period_types'] = 'Vacancy'
    when 'error-unavailable-period-args-not-all-same-size.xml'
      args['schedules_unavailable_period_types'] = 'Vacancy, Power Outage'
      args['schedules_unavailable_period_dates'] = 'Jan 1 - Jan 5, Jan 7 - Jan 9'
      args['schedules_unavailable_period_window_natvent_availabilities'] = HPXML::ScheduleRegular
    when 'error-unavailable-period-window-natvent-invalid.xml'
      args['schedules_unavailable_period_types'] = 'Power Outage'
      args['schedules_unavailable_period_dates'] = 'Jan 7 - Jan 9'
      args['schedules_unavailable_period_window_natvent_availabilities'] = 'invalid'
    when 'error-heating-perf-data-not-all-specified.xml'
      args['hvac_perf_data_heating_outdoor_temperatures'] = '47.0'
    when 'error-cooling-perf-data-not-all-specified.xml'
      args['hvac_perf_data_cooling_outdoor_temperatures'] = '95.0'
    when 'error-emissions-args-not-all-specified.xml'
      args['emissions_scenario_names'] = 'Scenario1'
    when 'error-emissions-args-not-all-same-size.xml'
      args['emissions_scenario_names'] = 'Scenario1'
      args['emissions_types'] = 'CO2e,CO2e'
      args['emissions_electricity_units'] = HPXML::EmissionsScenario::UnitsLbPerMWh
      args['emissions_electricity_values_or_filepaths'] = '../../HPXMLtoOpenStudio/resources/data/cambium/LRMER_MidCase.csv'
    when 'error-emissions-natural-gas-args-not-all-specified.xml'
      args['emissions_natural_gas_values'] = '117.6'
    when 'error-bills-args-not-all-same-size.xml'
      args['utility_bill_scenario_names'] = 'Scenario1'
      args['utility_bill_electricity_fixed_charges'] = '1'
      args['utility_bill_electricity_marginal_rates'] = '2,2'
    when 'error-invalid-aspect-ratio.xml'
      args['geometry_unit_aspect_ratio'] = -1
    when 'error-negative-foundation-height.xml'
      args['geometry_foundation_height'] = -8
    when 'error-too-many-floors.xml'
      args['geometry_unit_num_floors_above_grade'] = 7
    when 'error-invalid-garage-protrusion.xml'
      args['geometry_garage_protrusion'] = 1.5
    when 'error-sfa-no-non-adiabatic-walls.xml'
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_front_wall_is_adiabatic'] = true
      args['geometry_unit_back_wall_is_adiabatic'] = true
    when 'error-hip-roof-and-protruding-garage.xml'
      args['geometry_roof_type'] = Constants::RoofTypeHip
      args['geometry_garage_width'] = 12
      args['geometry_garage_protrusion'] = 0.5
    when 'error-protruding-garage-under-gable-roof.xml'
      args['geometry_unit_aspect_ratio'] = 0.5
      args['geometry_garage_width'] = 12
      args['geometry_garage_protrusion'] = 0.5
    when 'error-ambient-with-garage.xml'
      args['geometry_garage_width'] = 12
      args['geometry_foundation_type'] = HPXML::FoundationTypeAmbient
    when 'error-invalid-door-area.xml'
      args['door_area'] = -10
    when 'error-invalid-window-aspect-ratio.xml'
      args['window_aspect_ratio'] = 0
    when 'error-garage-too-wide.xml'
      args['geometry_garage_width'] = 72
    when 'error-garage-too-deep.xml'
      args['geometry_garage_width'] = 12
      args['geometry_garage_depth'] = 40
    when 'error-vented-attic-with-zero-floor-insulation.xml'
      args['ceiling_assembly_r'] = 0
    when 'error-different-software-program.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfd-header.xml')
      args['software_info_program_used'] = 'Program2'
      args['software_info_program_version'] = '2'
      args['emissions_scenario_names'] = 'Emissions2'
      args['utility_bill_scenario_names'] = 'Bills2'
    when 'error-different-simulation-control.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfd-header.xml')
      args['simulation_control_timestep'] = 10
      args['simulation_control_run_period'] = 'Jan 2 - Dec 30'
      args['simulation_control_run_period_calendar_year'] = 2008
      args['simulation_control_temperature_capacitance_multiplier'] = 2.0
      args['emissions_scenario_names'] = 'Emissions2'
      args['utility_bill_scenario_names'] = 'Bills2'
    when 'error-same-emissions-scenario-name.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfd-header.xml')
      args['emissions_electricity_values_or_filepaths'] = '2'
    when 'error-same-utility-bill-scenario-name.xml'
      args['existing_hpxml_path'] = File.join(File.dirname(__FILE__), 'extra_files/base-sfd-header.xml')
      args['utility_bill_electricity_fixed_charges'] = '13.0'
    when 'error-could-not-find-epw-file.xml'
      args['weather_station_epw_filepath'] = 'foo.epw'
    end

    # Warning
    case hpxml_file
    when 'warning-non-electric-heat-pump-water-heater.xml'
      args['water_heater_type'] = HPXML::WaterHeaterTypeHeatPump
      args['water_heater_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['water_heater_efficiency'] = 2.3
    when 'warning-sfd-slab-non-zero-foundation-height.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height_above_grade'] = 0.0
    when 'warning-mf-bottom-slab-non-zero-foundation-height.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height_above_grade'] = 0.0
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    when 'warning-slab-non-zero-foundation-height-above-grade.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args.delete('foundation_wall_insulation_distance_to_bottom')
    when 'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
      args['geometry_foundation_height'] = 3.0
      args['floor_over_foundation_assembly_r'] = 10
      args['foundation_wall_insulation_distance_to_bottom'] = 0.0
      args['foundation_wall_assembly_r'] = 10
    when 'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 3.0
      args['floor_over_foundation_assembly_r'] = 10
      args['foundation_wall_insulation_distance_to_bottom'] = 0.0
      args['foundation_wall_assembly_r'] = 10
    when 'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
      args['floor_over_foundation_assembly_r'] = 10
      args['foundation_wall_assembly_r'] = 10
    when 'warning-vented-attic-with-floor-and-roof-insulation.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeVented
      args['roof_assembly_r'] = 10
      args['ducts_supply_location'] = HPXML::LocationAtticVented
      args['ducts_return_location'] = HPXML::LocationAtticVented
    when 'warning-unvented-attic-with-floor-and-roof-insulation.xml'
      args['geometry_attic_type'] = HPXML::AtticTypeUnvented
      args['roof_assembly_r'] = 10
    when 'warning-conditioned-basement-with-ceiling-insulation.xml'
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementConditioned
      args['floor_over_foundation_assembly_r'] = 10
    when 'warning-conditioned-attic-with-floor-insulation.xml'
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['ducts_supply_location'] = HPXML::LocationConditionedSpace
      args['ducts_return_location'] = HPXML::LocationConditionedSpace
    when 'warning-geothermal-loop-but-no-gshp.xml'
      args['geothermal_loop_configuration'] = HPXML::GeothermalLoopLoopConfigurationVertical
    end
  end

  def _test_measure(runner, expected_errors, expected_warnings)
    # check warnings/errors
    if not expected_errors.nil?
      expected_errors.each do |expected_error|
        if runner.result.stepErrors.count { |s| s.include?(expected_error) } <= 0
          runner.result.stepErrors.each do |s|
            puts "ERROR: #{s}"
          end
        end
        assert(runner.result.stepErrors.count { |s| s.include?(expected_error) } > 0)
      end
    end
    if not expected_warnings.nil?
      expected_warnings.each do |expected_warning|
        if runner.result.stepWarnings.count { |s| s.include?(expected_warning) } <= 0
          runner.result.stepWarnings.each do |s|
            puts "WARNING: #{s}"
          end
        end
        assert(runner.result.stepWarnings.count { |s| s.include?(expected_warning) } > 0)
      end
    end
  end
end
