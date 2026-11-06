# frozen_string_literal: true

require 'csv'

module SamplingRegion
  # Finds the counties a sampling region covers, from the project's Sampling Region.tsv.
  # The TSV depends on County (v1/v3 regions) or on County and PUMA (v5/v6 regions, built from cells);
  # cells are translated to their counties through County.tsv.
  # @param characteristics_dir [String] Project housing characteristics directory
  # @param region [String] Sampling Region option of the building
  # @return [Array<String>] County option names, e.g. 'CO, Denver County'
  def self.counties(characteristics_dir, region)
    rows = CSV.read(File.join(characteristics_dir, 'Sampling Region.tsv'), headers: true, col_sep: "\t")
    option_col = "Option=#{region}"
    selected = rows.select { |row| row[option_col].to_s.strip == '1' }
    return selected.map { |row| row['Dependency=County'].to_s.strip }.uniq if rows.headers.include?('Dependency=County')

    cells = selected.to_h { |row| [row['Dependency=County and PUMA'].to_s.strip, true] }
    return counties_of_cells(File.join(characteristics_dir, 'County.tsv'), cells)
  end

  # Reads the county of each cell from County.tsv, which has one row per cell and a column per
  # county (over 3,000 in project_national), so only the rows of the wanted cells are split.
  # @param filepath [String] County.tsv path
  # @param cells [Hash] County and PUMA options to look up, as keys
  # @return [Array<String>] County option names
  def self.counties_of_cells(filepath, cells)
    header = nil
    counties = []
    File.foreach(filepath) do |line|
      line = line.chomp
      if header.nil?
        header = line.split("\t")
        next
      end
      next if line.start_with?('#')
      next unless cells.key?(line[0, line.index("\t").to_i])

      index = line.split("\t").index('1')
      counties << header[index].delete_prefix('Option=') if !index.nil? && header[index].start_with?('Option=')
    end
    return counties.uniq
  end
end
