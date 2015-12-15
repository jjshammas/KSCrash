#!/usr/bin/env ruby
#
# Moves all 'KS' classes into a 'BugsnagKS' namespace,
# and auxiliary classes into prefix.

require 'fileutils'
require 'pathname'

# Put all 'KS'-prefixed classes into 'BugsnagKS'
files = Dir.glob('Source/KSCrash/**/*.{h,m,pch,c,mm,cpp}')
files.each do |relpath|
  path = Pathname.new(relpath).realpath.to_s
  file = File.new(path)
  write_path = File.join(File.dirname(path), File.basename(path).gsub(/^KS/, "BugsnagKS"))
  contents = file.read.gsub(/[^\w]KS/, "BugsnagKS")
  File.open(write_path, "w+") do |write_file|
    write_file.write(contents)
  end
  FileUtils.rm(path) if write_path != path
end

# Avoid duplicate definition of RFC3339DateTool

TOP    = "#ifndef HDR_RFC3339DateTool_h\n#define HDR_RFC3339DateTool_h\n"
BOTTOM = "\n#endif\n"

File.open('Source/KSCrash/Recording/Tools/RFC3339DateTool.h', 'r+') do |file|
  contents = file.read
  unless contents.include?(TOP)
    contents.insert(0, TOP)
    contents << BOTTOM
    file.pos = 0
    file.write(contents)
  end
end

