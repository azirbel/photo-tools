require 'fileutils'
require 'exiftool_vendored'

class DatePieces
  attr_reader :year
  attr_reader :month
  attr_reader :day
  attr_reader :hour
  attr_reader :min
  attr_reader :sec

  def initialize(date_string)
    d = date_string.scan(/[0-9]+/)
    @year, @month, @day, @hour, @min, @sec = d
  end
end

class Renamer
  attr_reader :input_folder
  attr_reader :output_folder

  DEFAULT_CONFIG = {
    suffix: nil,
    create_month_folders: false,
  }

  MISSING_EXIF_FOLDER_NAME = 'missing-exif-data'

  def initialize(input_folder, config = {})
    @config = DEFAULT_CONFIG.merge(config)
    @input_folder = input_folder.gsub(/\/*$/, '')
    @output_folder = "#{@input_folder}-new"

    conflict_letter = 'a'
    while File.exist?(@output_folder) do
      @output_folder = "#{@input_folder}-new-#{conflict_letter}"
      conflict_letter.succ!
    end
  end

  def get_exif_dates(filepaths)
    files_with_dates = {}
    exif_data = Exiftool.new(filepaths)
    filepaths.map do |filepath|
      exif_result = exif_data.result_for(filepath)
      d_string = exif_result.to_hash[:date_time_original] || exif_result.to_hash[:create_date]
      files_with_dates[filepath] = d_string
    end

    return files_with_dates
  end

  # Generate a filename like
  # IMG_YYYYMMDD_hhmmss(_<suffix>).<ext>
  #
  # Handles conflicts with the existing plan - if a conflict is found, will add
  # a letter like:
  # IMG_YYYYMMDD_hhmmss<a>(_<suffix>).<ext>
  def generate_new_filepath(filepath, date_string, existing_plan, conflict_letter = nil)
    d = DatePieces.new(date_string)

    if @config[:create_month_folders]
      new_folder = File.join(@output_folder, "#{d.year}_#{d.month}")
    else
      new_folder = @output_folder
    end

    base = "IMG_#{d.year}#{d.month}#{d.day}_#{d.hour}#{d.min}#{d.sec}"
    suffix = @config[:suffix] ? "_#{@config[:suffix]}" : ''
    ext = File.extname(filepath).downcase
    new_filename = [base, conflict_letter || '', suffix, ext].join()

    new_filepath = File.join(new_folder, new_filename)

    if existing_plan.values.include?(new_filepath)
      new_letter = conflict_letter ? conflict_letter.succ : 'a'
      return generate_new_filepath(filepath, date_string, existing_plan, new_letter)
    else
      return new_filepath
    end
  end

  # files_with_dates: map (filepath -> exif_date_str)
  def make_rename_plan(files_with_dates)
    plan = {}
    files_with_dates.each do |filepath, date_string|
      if date_string
        new_filepath = generate_new_filepath(filepath, date_string, plan)
      else
        new_filepath = File.join(@output_folder, MISSING_EXIF_FOLDER_NAME, File.basename(filepath))
      end

      plan[filepath] = new_filepath
    end

    return plan
  end

  # TODO(azirbel): The CLI parts of this don't belong here.
  # Later I will try to use Renamer from a GUI as well.
  def interactive_rename
    filepaths = Dir.glob("#{@input_folder}/**/*").select{ |e| File.file? e }
    files_with_dates = get_exif_dates(filepaths)
    plan = make_rename_plan(files_with_dates)
    plan.each do |k, v|
      print "#{k} => #{v}\n"
    end

    print "\nContinue? [y/n] "
    should_continue = STDIN.gets

    if ['y', 'Y', 'yes', 'YES', 'Yes'].include?(should_continue.strip)
      FileUtils.mkdir_p(@output_folder)
      plan.each do |old_filename, new_filename|
        print '.'
        FileUtils.mkdir_p(File.dirname(new_filename))
        FileUtils.cp(old_filename, new_filename)

        # Preserve date accessed
        atime = File.atime(old_filename)

        # Try to reset date modified/created to time photo was taken
        mtime = File.mtime(old_filename)
        if files_with_dates[old_filename]
          d = DatePieces.new(files_with_dates[old_filename])
          mtime = Time.new(d.year, d.month, d.day, d.hour, d.min, d.sec)
        end

        File.utime(atime, mtime, new_filename)
      end
      print "\nDone.\n"
    else
      print "Aborting.\n"
    end
  end
end
