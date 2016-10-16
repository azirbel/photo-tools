#!/usr/bin/env ruby

description = <<-EOS
Rename photos to android convention (e.g. IMG_YYYYMMDD_hhmmss.jpg) using EXIF data.

Non-destructive: photos are copied to a [input-folder]-new folder and then renamed.

Usage:
  ./rename.rb [input-folder] (options)

Valid options:
EOS

require 'trollop'
require './renamer'

opts = Trollop::options do
  banner description
  opt :create_month_folders, "Create per-month folders", short: 'm'
  opt :suffix, "Suffix", type: String, short: 's'
end

input_folder = ARGV[0]

renamer = Renamer.new(input_folder, opts)
renamer.interactive_rename
