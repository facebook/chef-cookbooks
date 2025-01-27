# Copyright (c) 2022-present, Meta Platforms, Inc. and affiliates
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
description 'Ruby files which are empty, comments-only, ' +
   'or unparseable by RuboCop'
needs_rules ['NoParsedRuby']

def to_h
  no_parsed_ruby = {}
  Bookworm::InferRules::NoParsedRuby.keys.each do |key|
    plural = BOOKWORM_KEYS[key]['plural']
    no_parsed_ruby[plural] = []
    @kb.send(plural.to_sym).each do |k, metadata|
      no_parsed_ruby[plural].append(k) if metadata['NoParsedRuby']
    end
  end
  no_parsed_ruby
end

def to_plain
  hsh = to_h
  buffer = ''
  Bookworm::InferRules::NoParsedRuby.keys.each do |key|
    plural = BOOKWORM_KEYS[key]['plural']
    if hsh[plural].empty?
      buffer << "No non-AST #{plural} files\n"
    else
      buffer << "#{plural.capitalize}:\n"
      hsh[plural].sort.each do |keys|
        buffer << "\t#{keys}\n"
      end
    end
  end
  buffer
end
