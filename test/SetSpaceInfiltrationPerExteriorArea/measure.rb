# frozen_string_literal: true

# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SetSpaceInfiltrationPerExteriorArea < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SetSpaceInfiltrationPerExteriorArea'
  end

  # human readable description
  def description
    return 'Set Space Infiltration Design Flow Rate per exterior area for the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Replace this text with an explanation for the energy modeler specifically.  It should explain how the measure is modeled, including any requirements about how the baseline model must be set up, major assumptions, citations of references to applicable modeling resources, etc.  The energy modeler should be able to read this description and understand what changes the measure is making to the model and why these changes are being made.  Because the Modeler Description is written for an expert audience, using common abbreviations for brevity is good practice.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # add double argument for space infiltration target
    flow_per_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('flow_per_area', true)
    flow_per_area.setDisplayName('Flow per Exterior Surface Area.')
    flow_per_area.setUnits('CFM/ft^2')
    flow_per_area.setDefaultValue(0.05)
    args << flow_per_area

    # add choice argument for exterior surfaces vs. just walls
    choices = OpenStudio::StringVector.new
    choices << 'ExteriorArea'
    choices << 'ExteriorWallArea'
    ext_surf_cat = OpenStudio::Measure::OSArgument.makeChoiceArgument('ext_surf_cat', choices, true)
    ext_surf_cat.setDisplayName('Exterior surfaces to include')
    ext_surf_cat.setDefaultValue('ExteriorArea')
    args << ext_surf_cat

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    flow_per_area = runner.getDoubleArgumentValue('flow_per_area', user_arguments)
    ext_surf_cat = runner.getStringArgumentValue('ext_surf_cat', user_arguments)

    # check the flow_per_area for reasonableness
    if flow_per_area < 0
      runner.registerError('Please enter a non negative flow rate.')
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaceInfiltrationDesignFlowRates.size} SpaceInfiltrationDesignFlowRate objects and #{model.getSpaceInfiltrationEffectiveLeakageAreas.size} SpaceInfiltrationEffectiveLeakageArea objects.")

    # remove any SpaceInfiltrationEffectiveLeakageArea objects
    model.getSpaceInfiltrationEffectiveLeakageAreas.each(&:remove)

    # find most common lights schedule for use in spaces that do not have lights
    sch_hash = {}
    spaces_wo_infil = []
    # add schedules or infil directly assigned to space
    model.getSpaces.each do |space|
      space_has_infil = 0
      space_type_has_infil = 0
      space.spaceInfiltrationDesignFlowRates.each do |infil|
        if space_has_infil > 0
          runner.registerInfo("#{space.name} has more than one infiltration object, removing #{infil.name} to avoid excess infiltration in resulting model.")
          infil.remove
        end
        space_has_infil += 1
        next unless infil.schedule.is_initialized

        sch = infil.schedule.get
        if sch_hash.key?(sch)
          sch_hash[sch] += 1
        else
          sch_hash[sch] = 1
        end
      end
      # add schedule for infil assigned to space types
      if space.spaceType.is_initialized
        space.spaceType.get.spaceInfiltrationDesignFlowRates.each do |infil|
          if space_type_has_infil > 0
            runner.registerInfo("#{space_type.name} has more than one infiltration object, removing #{infil.name} to avoid excess infiltration in resulting model.")
            infil.remove
          end
          space_type_has_infil += 1
          next unless infil.schedule.is_initialized

          sch = infil.schedule.get
          if sch_hash.key?(sch)
            sch_hash[sch] += 1
          else
            sch_hash[sch] = 1
          end
        end
      end

      # identify spaces without infiltration and remove multiple infiltration from spaces
      if space_has_infil + space_type_has_infil == 0
        spaces_wo_infil << space
      elsif space_has_infil == 1 && space_type_has_infil == 1
        infil_to_rem = space.spaceInfiltrationDesignFlowRates.first
        runner.registerInfo("#{space.name} has infiltration object in both the space and space type, removing #{infil_to_rem.name} to avoid excess infiltration in resulting model.")
        infil_to_rem.remove
      end
    end
    most_comm_sch = sch_hash.key(sch_hash.values.max)

    # get target flow rate in ip
    flow_per_area_si = OpenStudio.convert(flow_per_area, 'ft/min', 'm/s').get

    # set infil for existing SpaceInfiltrationDesignFlowRate objects
    model.getSpaceInfiltrationDesignFlowRates.each do |infil|
      # TODO: - skip if this is unused space type
      next if infil.spaceType.is_initialized && infil.spaceType.get.floorArea == 0

      runner.registerInfo("Changing flow rate for #{infil.name}.")
      if ext_surf_cat == 'ExteriorWallArea'
        infil.setFlowperExteriorWallArea(flow_per_area_si)
      else # ExteriorArea
        infil.setFlowperExteriorSurfaceArea(flow_per_area_si)
      end
    end

    # add in new SpaceInfiltrationDesignFlowRate objects to any spaces taht don't have direct or inherited infiltration
    spaces_wo_infil.each do |space|
      infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      infil.setSchedule(most_comm_sch)
      runner.registerInfo("Adding new infiltration object to #{space.name} which did not initially have an infiltration object.")
      if ext_surf_cat == 'ExteriorWallArea'
        infil.setFlowperExteriorWallArea(flow_per_area_si)
      else # ExteriorArea
        infil.setFlowperExteriorSurfaceArea(flow_per_area_si)
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaceInfiltrationDesignFlowRates.size} SpaceInfiltrationDesignFlowRate objects and #{model.getSpaceInfiltrationEffectiveLeakageAreas.size} SpaceInfiltrationEffectiveLeakageArea objects.")

    return true
  end
end

# register the measure to be used by the application
SetSpaceInfiltrationPerExteriorArea.new.registerWithApplication
