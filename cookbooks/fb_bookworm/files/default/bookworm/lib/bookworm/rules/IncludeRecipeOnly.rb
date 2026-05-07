# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates
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
description 'Detects Ruby recipes containing only include_recipe calls ' +
            'with string literals'
keys ['recipe']

def_node_search :include_recipe_literals, '`(send nil? :include_recipe (str _))'

def output
  ast = @metadata['ast']
  return false if ast.type == :bookworm_found_nil
  children = if ast.begin_type?
               ast.children
             else
               [ast]
             end

  return false if children.empty?

  children.all? do |child|
    child.send_type? &&
      child.method_name == :include_recipe &&
      child.arguments.length == 1 &&
      child.first_argument.str_type?
  end
end
