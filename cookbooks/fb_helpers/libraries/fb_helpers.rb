# Copyright (c) 2016-present, Facebook, Inc.
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

require 'chef/json_compat'
require 'chef/log'

module FB
  # Various utility grab-bag.
  class Helpers
    NW_CHANGES_ALLOWED = '/run/chef/chef_nw_changes_allowed'.freeze
    NW_CHANGES_NEEDED = '/run/chef/chef_pending_nw_changes_needed'.freeze

    # attempt_lazy() should be used when attempting to write a lazy block to
    # an api attribute.
    #
    # Usage:
    #   attempt_lazy { my_var }
    #
    # Arguments:
    #   block: A block to be used by the DelayedEvaluator or evaluated
    #
    # Notes:
    # - For clients running a version of chef less than 17.0.42
    #   DelayedEvaluators will not be automatically called when they are
    #   read from the node object. To prevent breaking older clients, the
    #   passed in block will be evaluated immediately and a value will
    #   be returned instead of a DelayedEvaluator.
    def self.attempt_lazy(&block)
      if Chef::Version.new(Chef::VERSION) < Chef::Version.new('17.0.42')
        Chef::Log.warn(
          'fb_helpers.attempt_lazy: Lazy attributes are not supported on ' +
          'chef versions before 17.0.42. Evaluating block immediately ' +
          'and returning value rather than a DelayedEvaluator',
        )
        block.call
      else
        Chef::DelayedEvaluator.new { block.call }
      end
    end

    # evaluate_lazy_hash() should be used to evaluate an object that contains
    # DelayedEvaluators that will not be assigned to an attribute and hence be
    # evaluated
    #
    # Usage:
    #   evaluate_lazy_enumerable { my_enumerable }
    #
    # Arguments:
    #   my_enumerable: An enumerable that contains elements that should be evaluated
    #
    def self.evaluate_lazy_enumerable(my_enumerable)
      if my_enumerable.respond_to?(:each_pair)
        my_enumerable.each_pair do |key, value|
          if value.respond_to?(:each)
            evaluate_lazy_enumerable(value)
          elsif value.is_a?(::Chef::DelayedEvaluator)
            my_enumerable[key] = value.call
          end
        end
      elsif my_enumerable.respond_to?(:each)
        my_enumerable.each_with_index do |element, index|
          if element.respond_to?(:each)
            evaluate_lazy_enumerable(element)
          elsif element.is_a?(::Chef::DelayedEvaluator)
            my_enumerable[index] = element.call
          end
        end
      end
    end

    # commentify() takes a text string and converts it to a (possibly)
    # multi-line comment suitable for dropping into a config file.
    #
    # Usage:
    #   commentify(text, argHash)
    #
    # Arguments:
    #   text:    Required string. The string to convert to a comment
    #   arghash: An optional hash with the following (optional) keys:
    #   arghash['start']:     String to use for starting comment char(s)
    #                         Defaults to '#'
    #   arghash['finish']:    String used to close off entire
    #                         section of text, instead of leading each line
    #                         Defaults to empty string.
    #   arghash['width']:     Total line width (integer) of the config file.
    #                         Defaults to 80.
    #
    # Notes:
    # - 'text' arg will have all whitespace (including newlines) collapsed to a
    #   single space.
    # - If only 'start' is specified, string will be broken up into
    #   multiple lines, with each preceded by the start tag and padding
    # - If 'finish' is also specified, the entire string will be broken up
    #   similarly to above, except that only one leading and one trailing
    #   tag are used in total.
    # - Line width is the total width of the file you are inserting comments
    #   into, including the leading comment chars and padding
    # - Any words (tokens) longer than a full line are inserted at the start of
    #   their own line and printed contiguously in the config file. They will
    #   NOT be split up among multiple-lines.
    # - A minimum of one trailing space will be used as padding for each line
    def self.commentify(comment, arghash = {})
      defaults = { 'start' => '#', 'finish' => '', 'width' => 80 }
      arghash = defaults.merge(arghash)

      usage = %{
commentify(text, args)

commentify() takes one required string argument, followed by an optional hash.
If the has is specified, it takes one or more of the following keys:
'start', 'finish', 'width'
}

      # First arg must be a string that is not all whitespace
      if !comment.is_a?(String) || comment.match(/^\s*$/)
        fail usage
      end

      # Extract variable
      start = arghash['start']
      finish = arghash['finish']
      width = arghash['width']

      # Adjust the following variables to control padding:
      # - For comments with comment char at front of each line
      single_line_pad = 1
      # - Amount of padding at end of each line of all comments
      end_pad = 1

      # Contents of each line as we go
      curr_line = ''
      # Put comment in here to return
      final_comment = ''

      # >>> Start constructing the actual comment <<<
      # First thing to go into comment (always) is comment start tag
      curr_line = start

      # For multi-line comments, line-break right after initial start tag
      if finish == ''
        # For single-line comments, just pad and keep going w/ first line
        curr_line += ' ' * single_line_pad
        prefix = start + ' ' * single_line_pad
      else
        final_comment += "#{curr_line}\n"
        curr_line = ''
        prefix = ''
      end

      # Split on whitespace into an array
      words = comment.split(/\s+/)
      words.each do |word|
        # Determine how much writing space we have left
        space_avail = width - (curr_line.size + end_pad)
        # If the next word won't fit, handle a couple of special cases
        if word.length > space_avail
          # If we already have content on the line, then just line-break it
          if curr_line.empty?
            # If we get here, we are at start of line, and word is STILL
            # too long; force it in and violate the line-width.
            final_comment += "#{prefix}#{word}\n"
            curr_line = ''
          else
            final_comment += "#{curr_line.strip}\n"
            curr_line = "#{prefix}#{word} "
          end
        else
          # Space is available. Add word to line, adding start tag if needed
          if curr_line.empty?
            curr_line = prefix
          end
          curr_line += "#{word} "
        end
      end
      # No more words.
      # Add final line but only if the line already has content.
      unless curr_line.empty?
        final_comment += curr_line.strip
      end
      # Add closing comment if defined
      if finish != ''
        final_comment += "\n#{finish}"
      end
      final_comment
    end

    # filter_hash() takes two Hash objects and applies the second as a filter
    # on the first one.
    #
    # Usage:
    #   filter_hash(hash, filter)
    #
    # Arguments:
    #   hash: Required Hash. The Hash to be filtered
    #   filter: Required Hash. The filter to apply against hash
    #
    # Sample usage:
    # hash = {
    #   'foo' => 1,
    #   'bar' => 2,
    #   'baz' => {
    #     'cake' => 'asdf',
    #     'pie' => 42,
    #   },
    # }
    #
    # filter = ['foo', 'baz/cake']
    #
    # filter_hash(hash, filter) = {
    #   'foo' => 1,
    #   'baz' => {
    #     'cake' => 'asdf',
    #   },
    # }
    def self.filter_hash(hash, filter)
      self._filter_hash(hash, self._expand_filter(filter))
      # self._filter_hash_alt(hash, filter)
    end

    # helper method to convert AttributeAllowlist-style filters to something
    # usable by _filter_hash
    def self._expand_filter(array_filter)
      hash_filter = {}
      array_filter.each do |f|
        keys = f.split('/')
        h = nil
        keys.reverse_each do |k|
          h = { k => h }
        end
        self.merge_hash!(hash_filter, h)
      end
      hash_filter
    end

    # alternate implementation using AttributeAllowlist; does not work yet due
    # to https://github.com/chef/chef/issues/10276
    def self._filter_hash_alt(hash, filter)
      if FB::Version.new(Chef::VERSION) >= FB::Version.new('16.3')
        require 'chef/attribute_allowlist'
        Chef::AttributeAllowlist.filter(hash, filter)
      else
        require 'chef/whitelist'
        Chef::Whitelist.filter(hash, filter)
      end
    end

    # private method to implement filter_hash using recursion
    # note: we can't use Chef::AttributeAllowlist here because it doesn't
    # handle empty values properly at the moment
    def self._filter_hash(hash, filter, depth = 0)
      unless filter.is_a?(Hash)
        fail 'fb_helpers: the filter argument to filter_hash needs to be a ' +
          "Hash (actual: #{filter.class})"
      end

      filtered_hash = {}

      # We loop over the filter and pull out only allowed items from the hash
      # provided by the user. Since users might pass in something huge like
      # the entire saved node object, don't make the performance of this code
      # be defined by them.
      filter.each do |k, v|
        if hash.include?(k)
          if v.nil?
            filtered_hash[k] = hash[k]
          elsif v.is_a?(Hash)
            # we need to go deeper
            ret = self._filter_hash(hash[k], v, depth + 1)
            # if the filter returned nil, it means it had no matches, so
            # don't add it to the filtered_hash to avoid creating spurious
            # entries
            unless ret.nil?
              filtered_hash[k] = ret
            end
          else
            fail "fb_helpers: invalid filter passed to filter_hash: #{filter}"
          end
        else
          Chef::Log.debug(
            "fb_helpers: skipping key #{k} as it is missing from the hash",
          )
        end
      end

      # if we're recursing and get an empty hash here, it means we had no
      # matches; change it to nil so we can detect it appropriately in the
      # loop above
      if depth > 0 && filtered_hash == {}
        filtered_hash = nil
      end

      filtered_hash
    end

    # safe_dup() takes an object and duplicates it. This method always returns
    # a valid object, even if thing is not dup'able.
    #
    # This method is based on lib/chef/mixin/deep_merge.rb from
    # https://github.com/chef/chef at revision
    # 5c8383fedd13b07f13d64a58f7cc78664a235ced.
    #
    # Usage:
    #   safe_dup(thing)
    #
    # Arguments:
    #   thing: Required object. The object to duplicate.
    def self.safe_dup(thing)
      thing.dup
    rescue TypeError
      thing
    end

    # merge_hash() takes two hashes and returns the result of recursively
    # merging one onto the other. Only hashes are merged -- other objects,
    # including arrays, will be replaced. Leaf hashes are also merged by
    # default; this can be changed with overwrite_leaves, which will replace
    # them instead.
    #
    # This method is based on lib/chef/mixin/deep_merge.rb from
    # https://github.com/chef/chef at revision
    # 5c8383fedd13b07f13d64a58f7cc78664a235ced.
    #
    # Usage:
    #   merge_hash(merge_onto, merge_with, overwrite_leaves)
    #
    # Arguments:
    #   merge_onto: Required hash. The base hash that will be merged onto
    #   merge_with: Required hash. The hash that will be merged on merge_onto
    #   overwrite_leaves: Optional boolean. Whether to overwrite leaves or not
    def self.merge_hash(merge_onto, merge_with, overwrite_leaves = false)
      self.merge_hash!(safe_dup(merge_onto), safe_dup(merge_with),
                       overwrite_leaves)
    end

    # merge_hash!() takes two hashes and recursively merges one onto the
    # other, altering it in place, and returns the merged hash. See
    # merge_hash() for details on the merge semantics.
    #
    # This method is based on lib/chef/mixin/deep_merge.rb from
    # https://github.com/chef/chef at revision
    # 5c8383fedd13b07f13d64a58f7cc78664a235ced.
    #
    # Usage:
    #   merge_hash(merge_onto, merge_with, overwrite_leaves)
    #
    # Arguments:
    #   merge_onto: Required hash. The base hash that will be merged onto
    #   merge_with: Required hash. The hash that will be merged on merge_onto
    #   overwrite_leaves: Optional boolean. Whether to overwrite leaves or not
    def self.merge_hash!(merge_onto, merge_with, overwrite_leaves = false)
      # If there are two Hashes, recursively merge.
      if merge_onto.is_a?(Hash) && merge_with.is_a?(Hash)
        merge_with.each do |key, merge_with_value|
          is_leaf = false
          if overwrite_leaves && merge_with_value.is_a?(Hash)
            # if we're overwriting leaves, we need to know when we have one
            merge_with_value.each do |_k, v|
              if v.is_a?(Hash)
                is_leaf = true
                break
              end
            end
          end

          if merge_onto.key?(key)
            if is_leaf
              value = merge_onto[key]
              merge_with_value.each do |k, _v|
                value[k] = merge_with_value[k]
              end
            else
              value = self.merge_hash(merge_onto[key], merge_with_value,
                                      overwrite_leaves)
            end
          else
            value = merge_with_value
          end

          merge_onto[key] = value
        end
        merge_onto
      else
        # In all other cases, replace merge_onto with merge_with
        merge_with
      end
    end

    # parse_json() takes a JSON string and converts it to a Ruby object,
    # also enforcing that the top-level object matches what is expected.
    #
    # Usage:
    #   parse_json(json_string, top_level_class)
    #
    # Arguments:
    #   json_string: Required string. The JSON string to parse.
    #   top_level_class: Optional class, defaults to Hash.
    #   fallback: Optional boolean, defaults to false.
    def self.parse_json(json_string, top_level_class = Hash, fallback = false)
      unless [Array, Hash, String].include?(top_level_class)
        fail 'fb_helpers: top_level_class can only be Array, Hash or ' +
          "(actual: #{top_level_class})"
      end

      begin
        parsed_json = Chef::JSONCompat.parse(json_string)
      rescue Chef::Exceptions::JSON::ParseError => e
        m = 'fb_helpers: cannot parse string as JSON; returning an empty ' +
            "#{top_level_class} instead: #{e}"
        if fallback
          Chef::Log.error(m)
          return top_level_class.new
        else
          # rubocop:disable Style/SignalException
          fail m
          # rubocop:enable Style/SignalException
        end
      end

      unless parsed_json.is_a?(top_level_class)
        m = 'fb_helpers: parsed JSON does not match the expected ' +
            "#{top_level_class} (actual: #{parsed_json.class})"
        if fallback
          Chef::Log.error(m)
          return top_level_class.new
        else
          fail m
        end
      end

      parsed_json
    end

    # parse_json_file() takes a path string and converts its contents to a
    # Ruby object, also enforcing that the top-level object matches what is
    # expected.
    #
    # Usage:
    #   parse_json_file(path, top_level_class, fallback)
    #
    # Arguments:
    #   path: Required string. Path to the file to parse.
    #   top_level_class: Optional class, defaults to Hash.
    #   fallback: Optional boolean, defaults to false.
    def self.parse_json_file(path, top_level_class = Hash, fallback = false)
      Chef::Log.debug(
        "fb_helpers: parsing #{path} as JSON (expecting: #{top_level_class})",
      )

      begin
        content = File.read(path)
      rescue IOError, SystemCallError => e
        # SystemCallError is because of -ENOENT
        m = "fb_helpers: cannot read #{path}: #{e}"
        if fallback
          Chef::Log.error(m)
          return top_level_class.new
        else
          # rubocop:disable Style/SignalException
          fail m
          # rubocop:enable Style/SignalException
        end
      end

      self.parse_json(content, top_level_class, fallback)
    end

    # parse_simple_keyvalue_file() takes a path string which contains lines of
    # the form key=value and converts it to a ruby hash.
    #
    # Usage: parse_simple_keyvalue_file(path)
    #
    # Arguments:
    # path: Required string. Path to the file to parse.
    # options: Optional symbol / bool hash, designates non-default behaviors
    #  - :force_downcase - forces keys to lowercase values
    #  - :fallback - returns empty hash instead of an error in case of IOError on file
    #  - :empty_value_is_nil - k/v pairs where v.empty? is true have v coerced to nil
    #  - :include_whitespace - treats leading and trailing whitespace as semantic
    #  - :exclude_quotes strips surrounding quotes

    def self.parse_simple_keyvalue_file(path, options = {})
      parsed = {}
      begin
        IO.readlines(path).each do |line|
          (k, _, v) = line.chomp.partition('=').map { |x| options[:include_whitespace] ? x : x.strip }
          v.gsub!(/^['"](.*)['"]$/, '\1') if options[:exclude_quotes]
          parsed[options[:force_downcase] ? k.downcase : k] = (v == '' && options[:empty_value_is_nil]? nil : v)
        end
      rescue Errno::ENOENT => e
        if options[:fallback]
          Chef::Log.error("fb_helpers: cannot read #{path}: #{e}.  Returning empty hash")
        else
          raise "fb_helpers: cannot read #{path}: #{e}."
        end
      end
      parsed
    end

    # parse_timeshard_start() takes a time string and converts its contents to a
    # unix timestamp, to be used in computing timeshard information
    #
    # Usage:
    #   parse_timeshard_start(time)
    #
    # Arguments:
    #   time: A valid time string
    def self.parse_timeshard_start(time)
      # Validate the time string matches our prescribed format.
      begin
        st = Time.parse(time).tv_sec
      rescue ArgumentError
        errmsg = "fb_helpers: Invalid start_time arg '#{time}' for " +
                 'FB::Helpers.parse_timeshard_start'
        raise errmsg
      end
      st
    end

    # parse_timeshard_duration() takes a duration string and converts
    # its contents to a to an int to be used in computing timeshard information
    #
    # Usage:
    #   parse_timeshard_duration(duration)
    #
    # Arguments:
    #   duration: A valid duration string, in days or hours
    def self.parse_timeshard_duration(duration)
      # Multiply the number of days by 1440 min and 60 s to convert a day into
      # seconds.
      if duration.match('^[0-9]+[dD]$')
        duration = duration.to_i * 1440 * 60
      # Multiply the number of hours by 3600 s to convert hours into seconds.
      elsif duration.match('^[0-9]+[hH]$')
        duration = duration.to_i * 3600
      else
        errmsg = "fb_helpers: Invalid duration arg, '#{duration}' for " +
                 'FB::Helpers.parse_timeshard_duration'
        fail errmsg
      end
      duration
    end

    def self.linux?
      RUBY_PLATFORM.include?('linux')
    end

    def self.windows?
      RUBY_PLATFORM =~ /mswin|mingw32|windows/
    end

    # mountpoint? determines if a path string represents a mountpoint
    #
    # Usage:
    #   mountpoint?(path)
    #
    # Arguments:
    #   path: A string-compatible object that represents a path to test
    def self.mountpoint?(path)
      Pathname.new(path.to_s).mountpoint?
    end

    # date_of_last() takes a day of the week and finds the most recent
    # date this day fell on
    #
    # Usage:
    #   date_of_last(day)
    #
    # Arguments:
    #   day: A string representing a day of the week. Can be long-form
    #        (e.g. "Monday") or abbreviate (e.g. "Wed")
    def self.date_of_last(day)
      # Gets you the date of the last day passed
      date  = Date.parse(day)
      delta = date < Date.today ? 0 : 7
      (date - delta).to_s
    end

    # sysnative_path() determines the sysnative path on Windows
    def self.sysnative_path
      fail unless self.windows?

      if RUBY_PLATFORM.include?('64')
        "#{ENV['WINDIR']}\\system32\\"
      else
        "#{ENV['WINDIR']}\\sysnative\\"
      end
    end

    # warn_to_remove() is used in sharding operations to help
    # discover old sharding code
    def self.warn_to_remove(
      stack_depth, msg = 'fb_helpers: Past time shard duration! Please cleanup!'
    )
      stack = caller(stack_depth, 1)[0]
      parts = %r{^.*/cookbooks/([^/]*)/([^/]*)/(.*)\.rb:(\d+)}.match(stack)
      if parts
        where = "(#{parts[1]}::#{parts[3]} line #{parts[4]})"
      else
        where = stack
      end
      Chef::Log.warn("#{msg} #{where}")
    end

    # Normally preferred testing for existence of a user is via
    # node['etc']['passwd'], but if the user was added in the same chef run
    # then ohai won't have it.
    def self.user_exist?(user_name)
      Etc.getpwnam(user_name)
      true
    rescue ArgumentError
      false
    end

    # Normally preferred testing for existence of a group is via
    # node['etc']['group'], but if the group was added in the same chef run
    # then ohai won't have it.
    def self.group_exist?(group_name)
      Etc.getgrnam(group_name)
      true
    rescue ArgumentError
      false
    end

    def self.get_hwaddr(interface)
      addrfile = "/sys/class/net/#{interface}/address"
      return nil unless ::File.exist?(addrfile)
      ::File.read(addrfile).strip.upcase
    end

    def self._request_nw_changes_permission(run_context, new_resource)
      run_context.node.default['fb_helpers']['_nw_perm_requested'] = true
      notification = Chef::Resource::Notification.new(
        'fb_helpers_request_nw_changes[manage]',
        :request_nw_changes,
        new_resource,
      )
      notification.fix_resource_reference(run_context.resource_collection)
      run_context.root_run_context.add_delayed_action(notification)
    end

    # readfile() safely reads file content in a variable,
    # removing the last line termination.
    # It is suitable to read a single-liners (sysctl settings or similar).
    # It would return an empty string when the file is not avialable.
    #
    # Usage:
    #   readfile(path)
    #
    # Arguments:
    #   path: Required file path
    def self.readfile(filename)
      begin
        value = File.read(filename).chomp
      rescue Errno::ENOENT
        return ''
      end
      return value
    end
  end

  # Helper class to compare software versions.
  # Sample usage:
  #   Version.new('1.3') < Version.new('1.21')
  #   => true
  #   Version.new('4.5') < Version.new('4.5')
  #   => false
  #   Version.new('3.3.10') > Version.new('3.4')
  #   => false
  #   Version.new('10.2') >= Version.new('10.2')
  #   => true
  #   Version.new('1.2.36') == Version.new('1.2.36')
  #   => true
  #   Version.new('3.3.4') <= Version.new('3.3.02')
  #   => false

  # Our version comparison class
  class Version < Array
    # This is intentional.
    # rubocop:disable Lint/MissingSuper
    def initialize(s)
      @string_form = s
      if s.nil?
        @arr = []
        return
      end
      @arr = s.split(/[._-]/).map(&:to_i)
    end
    # rubocop:enable Lint/MissingSuper

    def to_s
      @string_form
    end

    def to_a
      @arr
    end

    def compare(other, exact = true)
      other ||= new
      unless other.is_a?(FB::Version)
        other = FB::Version.new(other)
      end
      if exact
        @arr <=> other.to_a
      else
        len = [@arr.length, other.to_a.length].min
        @arr[0, len] <=> other[0, len]
      end
    end

    alias_method '<=>', :compare

    def <=(other)
      compare(other) <= 0
    end

    def >=(other)
      compare(other) >= 0
    end

    def <(other)
      compare(other).negative?
    end

    def >(other)
      compare(other).positive?
    end

    def ==(other)
      compare(other).zero?
    end

    def [](*args)
      @arr[*args]
    end

    def ===(other)
      # Useful to use in case statements
      compare(other, false).zero?
    end

    # Oh, come on rubocop...
    def inspect
      @string_form
    end
  end
end
