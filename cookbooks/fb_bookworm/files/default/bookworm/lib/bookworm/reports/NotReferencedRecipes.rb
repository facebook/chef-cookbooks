# Copyright (c) 2023-present, Meta Platforms, Inc. and affiliates
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
description 'Determines all recipes that are not directly referenced either in roles or recipes'
needs_rules ['RoleRunListRecipes', 'IncludeRecipeLiterals', 'RecipeExists']

def to_a
  referenced_recipes = Set.new
  @kb.roles.each do |_, metadata|
    metadata['RoleRunListRecipes'].each do |role|
      referenced_recipes << role
    end
  end
  @kb.recipes.each do |_, metadata|
    metadata['IncludeRecipeLiterals'].each do |recipe|
      referenced_recipes << recipe
    end
  end
  @kb.recipejsons.each do |_, metadata|
    metadata['IncludeRecipeLiterals'].each do |recipe|
      referenced_recipes << recipe
    end
  end
  all_recipes = Set.new(@kb.recipes.keys + @kb.recipejsons.keys)
  # Any recipes which weren't included via roles or include_recipe are not referenced
  (all_recipes - referenced_recipes).sort.to_a
end

def output
  to_a
end
