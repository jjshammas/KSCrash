#!/usr/bin/env ruby
#
# Moves all 'KS' classes into a 'BugsnagKS' namespace,
# and auxiliary classes into prefix.

require 'fileutils'
require 'pathname'

def clean_text(text)
  text.gsub(/\bKS/, "BugsnagKS").gsub("RFC3339DateTool", "BugsnagRFC3339DateTool")
end

# Put all 'KS'-prefixed classes into 'BugsnagKS'
files = Dir.glob('Source/KSCrash/**/*.{h,m,pch,c,mm,cpp}')
files.each do |relpath|
  path = Pathname.new(relpath).realpath.to_s
  file = File.new(path)
  name = File.basename(path)
  write_path = File.join(File.dirname(path), clean_text(name))
  contents = clean_text(file.read)
  file.close
  File.open(write_path, "w+") do |write_file|
    write_file.write(contents)
  end
  FileUtils.rm(path) if write_path != path
end

