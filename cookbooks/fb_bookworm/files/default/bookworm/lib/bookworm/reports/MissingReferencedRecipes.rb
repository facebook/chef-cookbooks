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
description 'Determines all recipes that are directly referenced in roles and recipes' +
            ' but were not found by the crawler'
needs_rules ['RoleRunListRecipes', 'IncludeRecipeLiterals']

def to_h
  known_recipes = Set.new @kb.recipes.keys
  missing = { 'roles' => {}, 'recipes' => {} }
  @kb.roles.each do |role, metadata|
    metadata['RoleRunListRecipes'].each do |recipe|
      unless known_recipes.include? recipe
        missing['roles'][role] ||= []
        missing['roles'][role].append recipe
      end
    end
  end
  @kb.recipes.each do |kbrecipe, metadata|
    metadata['IncludeRecipeLiterals'].each do |recipe|
      unless known_recipes.include? recipe
        missing['recipes'][kbrecipe] ||= []
        missing['recipes'][kbrecipe].append recipe
      end
    end
  end
  missing
end

def to_plain
  hsh = to_h
  buffer = ''
  if hsh['roles'].empty?
    buffer << "No missing recipes coming from the roles files\n"
  else
    buffer << "Roles:\n"
    hsh['roles'].each do |role, recipes|
      buffer << "\t#{role}\t#{recipes.join(', ')}\n"
    end
  end
  if hsh['recipes'].empty?
    buffer << 'No missing recipes coming from the recipe files'
  else
    buffer << "Recipes:\n"
    hsh['recipes'].each do |kbrecipe, recipes|
      buffer << "\t#{kbrecipe}\t#{recipes.join(', ')}\n"
    end
  end
  buffer
end
