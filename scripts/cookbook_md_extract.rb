#!/usr/bin/ruby
#
# Copyright (c) 2025-present, Phil Dibowitz
# Copyright (c) 2025-present, Meta Platforms, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# A script that will extra metadata from a Chef Cookbook metadata file
# and print it. It prints it out on a single line, with no newline,
# space-separated for use in a shell variable.

def usage
  puts 'Usage: cookbook_md_extract <md_item> <metadata_file>'
  puts
  puts "  <md_item> is a field such as 'depends' or 'license'"
  puts '  <metadata_file> is the path to a metadata file'
end

def usage_error
  usage
  exit 1
end

what = ARGV.shift
md = ARGV.shift

usage_error unless what && md

# Rather than try to define every method in the metadata file, we'll just
# ignore method_missing and then define the one we care about
#
# we massage $VERBOSE to avoid the ruby errors about method_missing
#
# rubocop:disable Style/MethodMissing, Style/MissingRespondToMissing
old_verbose = $VERBOSE
$VERBOSE = nil
def method_missing(*keys); end
$VERBOSE = old_verbose
# rubocop:enable Style/MethodMissing, Style/MissingRespondToMissing

# define the method the user cares about
define_method(what) do |*args|
  args.each do |arg|
    print arg, ' '
  end
end

# grab only the lines that call our method
lines = []
File.readlines(md).each do |line|
  next unless line.match?(/#{what}/)
  lines << line
end

# eval the lines we grabbed
# rubocop:disable Security/Eval
eval(lines.join("\n"))
# rubocop:enable Security/Eval
