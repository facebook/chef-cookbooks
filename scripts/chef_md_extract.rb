#!/opt/chef/embedded/bin/ruby

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

# rubocop:disable Style/MethodMissing, Style/MissingRespondToMissing
def method_missing(*keys); end
# rubocop:enable Style/MethodMissing, Style/MissingRespondToMissing

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
