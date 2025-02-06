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
description 'Extracts recipes that are used by include_recipe with string literals'
keys ['recipe']

def_node_search :include_recipe_string_literals, '`(send nil? :include_recipe (str $_))'

def to_a
  arr = []
  include_recipe_string_literals(@metadata['ast']).each do |x|
    arr << x
  end
  return [] if arr.empty?
  arr.map! do |x|
    if x.start_with?('::')
      "#{@metadata['cookbook']}#{x}"
    elsif !x.include?('::')
      "#{x}::default"
    else
      x
    end
  end
  arr.uniq!
  arr.sort!
end
