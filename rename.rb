#!/usr/bin/env ruby

# Renames photos as IMG_YYYYMMDD_hhmmss.ext and moves them into folders by
# month.
#
# Non-destructive: will not replace existing files, and will copy the input
# files rather than moving them.
#
# Usage: ./rename.rb <input folder> <output folder>
#
# The tool will show a list of new files that will be created, and prompt you
# to continue or abort.

require 'fileutils'
require 'exiftool_vendored'

# Usage help
ARGV.each do |arg|
  if arg == '-h' || ARGV.length != 2
    puts "Usage: #{$0} <input folder> <output folder>"
    exit
  end
end

def pad(num)
  "%02d" % num
end

# String format YYYYMMDD_hhmmss
def datetime_string(d)
  "#{d[0]}#{d[1]}#{d[2]}_#{d[3]}#{d[4]}#{d[5]}"
end

def build_renames_map(filenames, output_folder)
  renames_map = {}
  exif_data = Exiftool.new(filenames)
  filenames.each do |filename|
    exif_result = exif_data.result_for(filename)
    # date_time_original for JPG, create_date for MOV
    d_string = exif_result.to_hash[:date_time_original] || exif_result.to_hash[:create_date]
    d = d_string.scan(/[0-9]+/) # Array of [year, month, day, hour, min, sec] as strings
    ext = File.extname(filename).downcase

    new_foldername = "#{d[0]}_#{d[1]}"
    FileUtils.mkdir_p("#{output_folder}/#{new_foldername}")

    new_filename = "#{output_folder}/#{new_foldername}/"\
      "IMG_#{datetime_string(d)}#{ext}"
    conflict_letter = 'a'
    while (File.exist?(new_filename) || renames_map.values.include?(new_filename)) do
      new_filename = "#{output_folder}/#{new_foldername}/"\
        "IMG_#{datetime_string(d)}#{conflict_letter}#{ext}"
      conflict_letter.succ!
    end

    renames_map[filename] = new_filename
  end

  renames_map
end

def execute_renames(renames_map)
  renames_map.each do |old_filename, new_filename|
    if (File.exist?(new_filename))
      # Shouldn't happen because renames_map should already handle collisions,
      # but be extra careful
      print "ERROR: File already exists: #{new_filename}"
      exit 1
    end

    print '.'
    FileUtils.cp(old_filename, new_filename)
  end
end

input_folder = ARGV[0]
output_folder = ARGV[1]

filenames = Dir.glob("#{input_folder}/**/*").select{ |e| File.file? e }
renames_map = build_renames_map(filenames, output_folder)
renames_map.each do |k, v|
  print "#{k} => #{v}\n"
end

print "\nContinue? [y/n] "
should_continue = STDIN.gets

if ['y', 'Y', 'yes', 'YES', 'Yes'].include?(should_continue.strip)
  print "Continuing.\n"
  execute_renames(renames_map)
  print "\nDone.\n"
else
  print "Aborting.\n"
end
