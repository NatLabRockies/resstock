# frozen_string_literal: true

# Object that stores collections of EnergyPlus meter names, units, and timeseries data.
class Fuel
  # @param meter [String] EnergyPlus meter name
  # @param fuel [String] fuel type (HPXML::FuelTypeXXX)
  def initialize(meter:, fuel:)
    @meter = meter
    @timeseries = []
    @units = UtilityBills.get_fuel_units(fuel)
  end
  attr_accessor(:meter, :timeseries, :units)
end

# Object that stores collections of fixed monthly rates, marginal rates, real-time rates, minimum monthly/annual charges, net metering and feed-in tariff information, and detailed tariff file information.
class UtilityRate
  def initialize()
    @flat_rate = 0.0
    @min_charge_monthly = 0.0
    @energy_rate_structure = []
    @energy_weekday_schedule = []
    @energy_weekend_schedule = []
  end
  attr_accessor(:fixed_charge_monthly, :fixed_charge_daily, :flat_rate, :real_time_prices,
                :min_charge_monthly, :min_charge_annual,
                :net_metering_excess_sellback_type, :net_metering_user_excess_sellback_rate,
                :feed_in_tariff_rate,
                :energy_rate_structure, :energy_weekday_schedule, :energy_weekend_schedule)
end

# Object that stores collections of monthly/annual/total fixed/energy charges, as well as monthly/annual production credit.
class UtilityBill
  def initialize()
    @annual_energy_charge = 0.0
    @annual_fixed_charge = 0.0
    @annual_total = 0.0
    @annual_production_credit = 0.0

    @monthly_energy_charge = [0.0] * 12
    @monthly_fixed_charge = [0.0] * 12
    @monthly_total = [0.0] * 12
    @monthly_production_credit = [0] * 12
  end
  attr_accessor(:annual_energy_charge, :annual_fixed_charge, :annual_total,
                :monthly_energy_charge, :monthly_fixed_charge, :monthly_total,
                :monthly_production_credit, :annual_production_credit)
end

# Collection of methods for calculating simple bills for all fuel types, as well as detailed bills for electricity.
module CalculateUtilityBill
  # Method for calculating utility bills based on simple utility rate structures.
  #
  # @param fuel_type [String] fuel type defined in the FT class
  # @param header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param fuel_time_series [Array<Double>] reported timeseries data from the fuel meter
  # @param is_production [Boolean] fuel meter is PV production or not
  # @param rate [UtilityRate] UtilityRate object
  # @param bill [UtilityBill] UtilityBill object
  # @param net_elec [Double] net electricity production tallied by month
  # @return [Double] net electricity production for the run period
  def self.simple(fuel_type, header, fuel_time_series, is_production, rate, bill, net_elec)
    if fuel_time_series.size > 12
      # Must be no more than 12 months worth of simulation data
      fail 'Incorrect timeseries data.'
    end

    monthly_fuel_cost = [0] * 12
    for month in 0..fuel_time_series.size - 1
      month_ix = month + header.sim_begin_month - 1

      if is_production && fuel_type == FT::Elec && rate.feed_in_tariff_rate
        monthly_fuel_cost[month_ix] = fuel_time_series[month] * rate.feed_in_tariff_rate
      else
        monthly_fuel_cost[month_ix] = fuel_time_series[month] * rate.flat_rate
      end

      if fuel_type == FT::Elec
        if is_production # has PV
          net_elec -= fuel_time_series[month]
        else
          net_elec += fuel_time_series[month]
        end
      end

      if is_production
        bill.monthly_production_credit[month_ix] = monthly_fuel_cost[month_ix]
      else
        bill.monthly_energy_charge[month_ix] = monthly_fuel_cost[month_ix]
        monthly_charge = rate.fixed_charge_monthly.to_f
        monthly_charge += rate.fixed_charge_daily.to_f * Calendar.num_days_in_months(header.sim_calendar_year)[month_ix]
        bill.monthly_fixed_charge[month_ix] = monthly_charge * calculate_monthly_prorate(header, month_ix + 1)
      end
    end

    bill.annual_energy_charge = bill.monthly_energy_charge.sum(0.0)
    bill.annual_fixed_charge = bill.monthly_fixed_charge.sum(0.0)
    bill.annual_production_credit = bill.monthly_production_credit.sum(0.0)

    if is_production && rate.net_metering_excess_sellback_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
      # Annual True-Up
      # Only make changes for cases where there's a user specified annual excess sellback rate
      if bill.annual_production_credit > bill.annual_energy_charge
        bill.annual_production_credit = bill.annual_energy_charge
      end
      if net_elec < 0 # net producer, give credit at user specified rate
        bill.annual_production_credit += -net_elec * rate.net_metering_user_excess_sellback_rate
      end
    end
    return net_elec
  end

  # Method for calculating electric utility bills based on detailed utility rate structures.
  #
  # @param header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param fuels [Hash] Fuel type, is_production => Fuel object
  # @param rate [UtilityRate] UtilityRate object
  # @param bill [UtilityBill] UtilityBill object
  # @return [nil]
  def self.detailed_electric(header, fuels, rate, bill)
    fuel_time_series = fuels[[FT::Elec, false]].timeseries
    production_fuel_time_series = fuels[[FT::Elec, true]].timeseries

    if fuel_time_series.size < 24 || production_fuel_time_series.size < 24
      # Must be at least 24 hours worth of simulation data
      fail 'Incorrect timeseries data.'
    end

    year = header.sim_calendar_year
    start_day = DateTime.new(year, header.sim_begin_month, header.sim_begin_day)
    today = start_day

    net_monthly_energy_charge = [0] * 12
    production_fit_month = [0] * 12

    has_production = (production_fuel_time_series.sum > 0)

    elec_month = [0] * 12
    net_elec_month = [0] * 12

    if !rate.real_time_prices.nil?
      num_periods = 0
      num_tiers = 0
    else
      num_periods = rate.energy_rate_structure.size
      num_tiers = rate.energy_rate_structure.map { |period| period.size }.max

      rate.energy_rate_structure.each do |period|
        period.each do |tier|
          tier[:rate] += tier[:adj] if tier.keys.include?(:adj)
        end
      end

      tier = 0
      net_tier = 0
      elec_period = [0] * num_periods
      elec_tier = [0] * num_tiers
      if has_production
        net_elec_period = [0] * num_periods
        net_elec_tier = [0] * num_tiers
      end
    end

    for hour in 0..fuel_time_series.size - 1
      hour_day = hour % 24 # calculate hour of the day

      month = today.month - 1

      elec_hour = fuel_time_series[hour]
      elec_month[month] += elec_hour

      if has_production
        pv_hour = production_fuel_time_series[hour]
        net_elec_hour = elec_hour - pv_hour
        net_elec_month[month] += net_elec_hour
      end

      if !rate.real_time_prices.nil?
        # Real-Time Pricing
        bill.monthly_energy_charge[month] += elec_hour * rate.real_time_prices[hour]

        if has_production
          if rate.feed_in_tariff_rate
            production_fit_month[month] += pv_hour * rate.feed_in_tariff_rate
          else
            net_monthly_energy_charge[month] += net_elec_hour * rate.real_time_prices[hour]
          end
        end

      else
        # Tiered and/or Time-of-Use

        if (num_periods != 0) || (num_tiers != 0)
          if (1..5).to_a.include?(today.wday) # weekday
            sched_rate = rate.energy_weekday_schedule[month][hour_day]
          else # weekend
            sched_rate = rate.energy_weekend_schedule[month][hour_day]
          end
        end

        if (num_periods > 1) || (num_tiers > 1) # tiered or TOU
          tiers = rate.energy_rate_structure[sched_rate]

          if num_tiers > 1

            # init
            new_tier = false
            if tiers.size > 1 && tier < tiers.size
              if tiers[tier].keys.include?(:max) && elec_month[month] >= tiers[tier][:max]
                tier += 1
                new_tier = true
                elec_lower_tier = elec_hour - (elec_month[month] - tiers[tier - 1][:max])
              end
            end

            if num_periods == 1 # tiered only
              if new_tier
                bill.monthly_energy_charge[month] += (elec_lower_tier * tiers[tier - 1][:rate]) + ((elec_hour - elec_lower_tier) * tiers[tier][:rate])
              else
                bill.monthly_energy_charge[month] += elec_hour * tiers[tier][:rate]
              end
            else # tiered and TOU
              elec_period[sched_rate] += elec_hour
              if (tier > 0) && (tiers.size == 1)
                elec_tier[0] += elec_hour
              else
                if new_tier
                  elec_tier[tier - 1] += elec_lower_tier
                  elec_tier[tier] += elec_hour - elec_lower_tier
                else
                  elec_tier[tier] += elec_hour
                end
              end

            end
          else # TOU only
            bill.monthly_energy_charge[month] += elec_hour * tiers[0][:rate]
          end
        else # not tiered or TOU
          bill.monthly_energy_charge[month] += elec_hour * rate.energy_rate_structure[0][0][:rate]
        end

        if has_production
          if rate.feed_in_tariff_rate
            production_fit_month[month] += pv_hour * rate.feed_in_tariff_rate
          else
            if (num_periods > 1) || (num_tiers > 1)
              if num_tiers > 1

                # init
                net_new_tier = false
                net_lower_tier = false
                if tiers.size > 1
                  if net_tier < tiers.size && tiers[net_tier].keys.include?(:max) && net_elec_month[month] >= tiers[net_tier][:max]
                    net_tier += 1
                    net_new_tier = true
                    net_elec_lower_tier = net_elec_hour - (net_elec_month[month] - tiers[net_tier - 1][:max])
                  end
                  if net_tier > 0 && tiers[net_tier - 1].keys.include?(:max) && net_elec_month[month] < tiers[net_tier - 1][:max]
                    net_tier -= 1
                    net_lower_tier = true
                    net_elec_upper_tier = net_elec_hour - (net_elec_month[month] - tiers[net_tier][:max])
                  end
                end

                if num_periods == 1 # tiered only
                  if net_new_tier
                    net_monthly_energy_charge[month] += (net_elec_lower_tier * tiers[net_tier - 1][:rate]) + ((net_elec_hour - net_elec_lower_tier) * tiers[net_tier][:rate])
                  elsif net_lower_tier
                    net_monthly_energy_charge[month] += (net_elec_upper_tier * tiers[net_tier + 1][:rate]) + ((net_elec_hour - net_elec_upper_tier) * tiers[net_tier][:rate])
                  else
                    net_monthly_energy_charge[month] += net_elec_hour * tiers[net_tier][:rate]
                  end
                else # tiered and TOU
                  net_elec_period[sched_rate] += net_elec_hour
                  if (net_tier > 0) && (tiers.size == 1)
                    net_elec_tier[0] += net_elec_hour
                  else
                    if net_new_tier
                      net_elec_tier[net_tier - 1] += net_elec_lower_tier
                      net_elec_tier[net_tier] += net_elec_hour - net_elec_lower_tier
                    elsif net_lower_tier
                      net_elec_tier[net_tier + 1] += net_elec_upper_tier
                      net_elec_tier[net_tier] += net_elec_hour - net_elec_upper_tier
                    else
                      net_elec_tier[net_tier] += net_elec_hour
                    end
                  end
                end
              else # TOU only
                net_monthly_energy_charge[month] += net_elec_hour * tiers[0][:rate]
              end
            else # not tiered or TOU
              net_monthly_energy_charge[month] += net_elec_hour * rate.energy_rate_structure[0][0][:rate]
            end
          end
        end
      end

      next unless hour_day == 23 # last hour of the day

      if Calendar.day_end_months(year).include?(today.yday)
        monthly_charge = rate.fixed_charge_monthly.to_f
        monthly_charge += rate.fixed_charge_daily.to_f * Calendar.num_days_in_months(header.sim_calendar_year)[month]
        bill.monthly_fixed_charge[month] = monthly_charge * calculate_monthly_prorate(header, month + 1)

        if (num_periods > 1) || (num_tiers > 1) # tiered or TOU

          if num_periods > 1 && num_tiers > 1 # tiered and TOU
            frac_elec_period = [0] * num_periods
            for period in 0..num_periods - 1
              frac_elec_period[period] = elec_period[period] / elec_month[month]
              for t in 0..rate.energy_rate_structure[period].size - 1
                if t < elec_tier.size
                  bill.monthly_energy_charge[month] += rate.energy_rate_structure[period][t][:rate] * frac_elec_period[period] * elec_tier[t]
                end
              end
            end
          end

          elec_period = [0] * num_periods
          elec_tier = [0] * num_tiers
          tier = 0
        end

        if has_production && !rate.feed_in_tariff_rate # has PV
          if (num_periods > 1) || (num_tiers > 1) # tiered or TOU

            if num_periods > 1 && num_tiers > 1 # tiered and TOU
              net_frac_elec_period = [0] * num_periods
              for period in 0..num_periods - 1
                net_frac_elec_period[period] = net_elec_period[period] / net_elec_month[month]
                for t in 0..rate.energy_rate_structure[period].size - 1
                  if t < net_elec_tier.size
                    net_monthly_energy_charge[month] += rate.energy_rate_structure[period][t][:rate] * net_frac_elec_period[period] * net_elec_tier[t]
                  end
                end
              end
            end

            net_elec_period = [0] * num_periods
            net_elec_tier = [0] * num_tiers
            net_tier = 0
          end
        end

        if has_production
          if rate.feed_in_tariff_rate
            bill.monthly_production_credit[month] = production_fit_month[month]
          else
            bill.monthly_production_credit[month] = bill.monthly_energy_charge[month] - net_monthly_energy_charge[month]
          end
          bill.annual_production_credit += bill.monthly_production_credit[month]
        end
      end

      today += 1 # next day
    end # for hour in 0..fuel_time_series.size-1

    annual_total_charge = bill.monthly_energy_charge.sum + bill.monthly_fixed_charge.sum

    if has_production && !rate.feed_in_tariff_rate # Net metering calculations

      annual_payments, monthly_min_charges, end_of_year_bill_credit = apply_min_charges(bill.monthly_fixed_charge, net_monthly_energy_charge, rate.min_charge_annual, rate.min_charge_monthly)
      end_of_year_bill_credit, excess_sellback = apply_excess_sellback(end_of_year_bill_credit, rate.net_metering_excess_sellback_type, rate.net_metering_user_excess_sellback_rate, net_elec_month.sum(0.0))

      annual_total_charge_with_pv = annual_payments + end_of_year_bill_credit - excess_sellback
      bill.annual_production_credit = annual_total_charge - annual_total_charge_with_pv

      for m in 0..11
        bill.monthly_fixed_charge[m] += monthly_min_charges[m]
      end

    else # Either no PV or PV with FIT
      if rate.min_charge_annual.nil?
        for m in 0..11
          monthly_bill = bill.monthly_energy_charge[m] + bill.monthly_fixed_charge[m]
          if monthly_bill < rate.min_charge_monthly
            bill.monthly_fixed_charge[m] += (rate.min_charge_monthly - monthly_bill)
          end
        end
      else
        if annual_total_charge < rate.min_charge_annual
          bill.monthly_fixed_charge[11] += (rate.min_charge_annual - annual_total_charge)
        end
      end
    end

    bill.annual_fixed_charge = bill.monthly_fixed_charge.sum
    bill.annual_energy_charge = bill.monthly_energy_charge.sum
  end

  # For net metering calculations, calculate monthly payments, rollover, and min charges.
  #
  # @param monthly_fixed_charge [Double] the sum of monthly fixed electricity charges (USD)
  # @param net_monthly_energy_charge [Array<Double>] array of monthly net energy charges (USD)
  # @param annual_min_charge [Double] the minimum annual electricity charge (USD)
  # @param monthly_min_charge [Double] the minimum monthly electricity charge  (USD)
  # @return [Array<Double, Array<Double>, Double>] annual payments, array of monthly minimum charges, end of year bill credit (USD)
  def self.apply_min_charges(monthly_fixed_charge, net_monthly_energy_charge, annual_min_charge, monthly_min_charge)
    monthly_min_charges = [0] * 12
    if annual_min_charge.nil?
      monthly_payments = [0] * 12
      monthly_rollover = [0] * 12
      for m in 0..11
        net_monthly_bill = net_monthly_energy_charge[m] + monthly_fixed_charge[m]
        # Pay bill if rollover can't cover it, or just pay min.
        monthly_payments[m] = [net_monthly_bill + monthly_rollover[m - 1], monthly_fixed_charge[m]].max
        if monthly_payments[m] < monthly_min_charge
          monthly_min_charges[m] += monthly_min_charge - monthly_payments[m]
        end
        monthly_rollover[m] += (monthly_rollover[m - 1] + net_monthly_bill - monthly_payments[m])
      end
      annual_payments = monthly_payments.sum
      end_of_year_bill_credit = monthly_rollover[-1]

    else
      annual_fixed_charge = monthly_fixed_charge.sum
      net_annual_bill = net_monthly_energy_charge.sum + annual_fixed_charge
      annual_payments = [net_annual_bill, annual_fixed_charge].max

      if annual_payments < annual_min_charge
        monthly_min_charges[11] = annual_min_charge - annual_payments
      end
      end_of_year_bill_credit = net_annual_bill - annual_payments
    end

    return annual_payments, monthly_min_charges, end_of_year_bill_credit
  end

  # For net metering calculations, apply the excess sellback.
  #
  # @param end_of_year_bill_credit [Double] end of year bill credit (USD)
  # @param net_metering_excess_sellback_type [String] net metering annual excess sellback rate type
  # @param net_metering_user_excess_sellback_rate [Double] user-specified net metering annual excess sellback rate
  # @param net_elec [Double] net electricity production for the run period
  # @return [Array<Double, Double>] end of year bill credit, excess sellback
  def self.apply_excess_sellback(end_of_year_bill_credit, net_metering_excess_sellback_type, net_metering_user_excess_sellback_rate, net_elec)
    # Note: Annual excess sellback can only be calculated at the end of the year on the net electricity consumption.
    if net_metering_excess_sellback_type == HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
      excess_sellback = 0
    else
      excess_sellback = -[net_elec, 0].min * net_metering_user_excess_sellback_rate
      end_of_year_bill_credit = 0
    end

    return end_of_year_bill_credit, excess_sellback
  end

  # If the run period doesn't span the entire month, prorate the fixed charges
  #
  # @param header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param month [Integer] the month index
  # @return [Double] for partial month bills, the fraction of days in the run period
  def self.calculate_monthly_prorate(header, month)
    begin_month = header.sim_begin_month
    begin_day = header.sim_begin_day
    end_month = header.sim_end_month
    end_day = header.sim_end_day
    year = header.sim_calendar_year

    if month < begin_month || month > end_month
      num_days_in_month = 0
    else
      if month == begin_month
        day_begin = begin_day
      else
        day_begin = 1
      end
      if month == end_month
        day_end = end_day
      else
        day_end = Calendar.num_days_in_months(year)[month - 1]
      end
      num_days_in_month = day_end - day_begin + 1
    end

    return num_days_in_month.to_f / Calendar.num_days_in_months(year)[month - 1]
  end
end

# String handling for fields in the usurdb.csv file.
#
# @param x [String] the utility/name contained in the usurdb.csv file
# @return [String] the utility/name after having removed non-alphanumeric characteristics and multiple spaces
def valid_filename(x)
  x = "#{x}".gsub(/[^0-9A-Za-z\s]/, '') # remove non-alphanumeric
  x = "#{x}".gsub(/\s+/, ' ').strip # remove multiple spaces
  return x
end

# Parse the usurdb csv, select residential rates, and export into individual json files.
#
# @param filepath [String] path to the usurdb.csv file downloaded from openei
# @return [Integer] the number of exported utility rate json files
def process_usurdb(filepath)
  # Map csv found at https://openei.org/apps/USURDB/download/usurdb.csv.gz to
  # https://openei.org/services/doc/rest/util_rates/?version=7#response-fields
  require 'csv'
  require 'json'
  require 'zip'

  skip_keywords = [
    'lighting',
    'lights',
    'private light',
    'yard light',
    'security light',
    'lumens',
    'watt hps',
    'incandescent',
    'halide',
    'lamps',
    '[partial]',
    'rider',
    'irrigation',
    'grain'
  ]

  puts 'Parsing CSV...'
  rates = CSV.read(filepath, headers: true)

  puts 'Creating hashes...'
  rates = rates.map { |d| d.to_hash }

  puts 'Selecting residential rates...'
  residential_rates = []
  rates.each do |rate|
    # rates to skip
    next if rate['sector'] != 'Residential'
    next if !rate['enddate'].nil? # Exclude rates that no longer apply
    next if skip_keywords.any? { |x| rate['name'].downcase.include?(x) }

    # unhandled fixed charge units
    if (not ['$/day', '$/month'].include?(rate['fixedchargeunits'])) && (rate['fixedchargefirstmeter'].to_f > 0)
      next
    end

    # unhandled min charge units
    if (not ['$/month', '$/year'].include?(rate['minchargeunits'])) && (rate['mincharge'].to_f > 0)
      next
    end

    # ignore blank fields
    rate.each do |k, v|
      rate.delete(k) if v.nil?
    end

    # map schedules and structures
    structures = {}
    rate.each do |k, v|
      if ['eiaid'].include?(k)
        rate[k] = Integer(Float(v))
      elsif k.include?('schedule')
        # all of a sudden some fields have an "L" character (?)
        rate[k] = eval(v.gsub('L', '')) # arrays
      elsif k.include?('structure')
        rate.delete(k)

        k, period, tier = k.split('/')
        period_idx = Integer(period.gsub('period', ''))
        tier_idx = nil
        tier_name = nil
        ['max', 'unit', 'rate', 'adj', 'sell'].each do |k2|
          if tier.include?(k2)
            tier_idx = Integer(tier.gsub('tier', '').gsub(k2, ''))
            tier_name = k2
          end
        end

        # init
        if !structures.keys.include?(k)
          structures[k] = []
        end
        if structures[k].size == period_idx
          structures[k] << []
        end
        if structures[k][period_idx].size == tier_idx
          structures[k][period_idx] << {}
        end

        begin
          v = Float(v)
        rescue # string
        end

        structures[k][period_idx][tier_idx][tier_name] = v
      else # not eiaid, schedule, or structure
        begin
          rate[k] = Float(v)
        rescue # string
        end
      end
    end

    rate.update(structures)

    # ignore rates with demand charges
    next if !rate['demandweekdayschedule'].nil? || !rate['demandweekendschedule'].nil? || !rate['demandratestructure'].nil? || !rate['flatdemandstructure'].nil?

    # ignore rates without minimum fields
    next if rate['energyweekdayschedule'].nil? || rate['energyweekendschedule'].nil? || rate['energyratestructure'].nil?

    # ignore rates without a "rate" key
    next if rate['energyratestructure'].collect { |r| r.collect { |s| !s.keys.include?('rate') } }.flatten.any?

    # ignore rates with negative "rate" value
    next if rate['energyratestructure'].collect { |r| r.collect { |s| s['rate'] < 0 } }.flatten.any?

    # ignore rates with a "sell" key
    next if rate['energyratestructure'].collect { |r| r.collect { |s| s.keys } }.flatten.uniq.include?('sell')

    # ignore rates where max usage is provided but max units are not 'kWh'
    next if rate['energyratestructure'].collect { |r| r.collect { |s| s['unit'] != 'kWh' && s.keys.include?('max') } }.flatten.any?

    residential_rates << { 'items' => [rate] }
  end

  FileUtils.rm(filepath)

  puts 'Exporting residential rates...'
  rates_dir = File.dirname(filepath)
  zippath = File.join(rates_dir, 'openei_rates.zip')
  FileUtils.rm(zippath)
  ratepaths = []
  Zip::File.open(zippath, create: true) do |zipfile|
    residential_rates.each do |residential_rate|
      utility = valid_filename(residential_rate['items'][0]['utility'])
      name = valid_filename(residential_rate['items'][0]['name'])
      startdate = residential_rate['items'][0]['startdate']

      filename = "#{utility} - #{name}"
      filename += " (Effective #{startdate.split(' ')[0]})" if !startdate.nil?

      ratepath = File.join(rates_dir, "#{filename}.json")
      File.open(ratepath, 'w') do |f|
        json = JSON.pretty_generate(residential_rate)
        f.write(json)
      end
      next if ratepaths.include?(ratepath)

      zipfile.add(File.basename(ratepath), ratepath)
      ratepaths << ratepath
    end
  end

  ratepaths.each do |ratepath|
    FileUtils.rm(ratepath)
  end

  return ratepaths.count
end
