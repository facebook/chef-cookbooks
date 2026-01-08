#!/opt/chef/embedded/bin/ruby
#
# Copyright (c) Meta Platforms, Inc. and affiliates.
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

def usage
  puts 'Usage: chef_md_extract <what> <metadata_file>'
  puts
  puts "  <what> is a field such as 'depends' or 'license'"
  puts '  <metadata_file> is the path to a metadata file'
  puts
  puts "WARNING: 'long_description' is not a supported <what>"
end

def usage_error
  usage
  exit 1
end

what = ARGV[0]
md = ARGV[1]

usage_error unless what && md
usage_error if what == 'long_description'

# define the method the user cares about
define_method(what) do |a|
  print a, ' '
end

# Disable Ruby warnings about redefining method_missing
old_v = $VERBOSE
$VERBOSE = nil
# rubocop:disable Style/MethodMissing, Style/MissingRespondToMissing
def method_missing(*keys); end
# rubocop:enable Style/MethodMissing, Style/MissingRespondToMissing
$VERBOSE = old_v

# grab only the lines that call our method
lines = []
File.readlines(md).each do |line|
  type = line.split.first
  # long_description uses IO.read and crazy stuff that breaks
  next if type == 'long_description'
  # Community cookbooks use a version number in the metadata,
  # EX: depends 'windows', '>= 1.2.8'
  # This line will drop ',.*' only on depends lines
  lines << (type == 'depends' ? line.split(',').first : line)
end

# eval the lines we grabbed
# rubocop:disable Security/Eval
eval(lines.join("\n"))
# rubocop:enable Security/Eval
