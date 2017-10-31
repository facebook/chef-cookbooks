# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
module FB
  # Various utility grab-bag.
  class Helpers
    # commentify() takes a text string and converts it to a (possibly)
    # multi-line comment suitable for dropping into a config file.
    #
    # Usage:
    #   commentify(text, argHash)
    #
    # Arguments:
    #   text:    Required string. The string to convert to a commnent
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
      if finish != ''
        final_comment += "#{curr_line}\n"
        curr_line = ''
        prefix = ''
      else
        # For single-line comments, just pad and keep going w/ first line
        curr_line += ' ' * single_line_pad
        prefix = start + ' ' * single_line_pad
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
      return final_comment
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
    def initialize(s)
      @string_form = s
      if s.nil?
        @arr = []
        return
      end
      @arr = s.split('.').map(&:to_i)
    end

    def to_s
      return @string_form
    end

    def to_a
      return @arr
    end

    def <=(other)
      other ||= []
      return (@arr <=> other.to_a) <= 0
    end

    def >=(other)
      other ||= []
      return (@arr <=> other.to_a) >= 0
    end

    def <(other)
      other ||= []
      return (@arr <=> other.to_a) < 0
    end

    def >(other)
      other ||= []
      return (@arr <=> other.to_a) > 0
    end

    def ==(other)
      other ||= []
      return (@arr <=> other.to_a).zero?
    end

    def <=>(other)
      @arr <=> other.to_a
    end

    # Oh, come on rubocop...
    # rubocop:disable TrivialAccessors
    def inspect
      @string_form
    end
    # rubocop:enable TrivialAccessors
  end
end
