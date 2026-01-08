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

# This report determines what can be safely removed from a cookbook's
# metadata.rb file. The benefit to this is that a client is less likely to
# download unnecessary cookbooks as part of the run synchronization, and makes
# dead code identification easier.

# TODO: need to add/include definitions key to be entirely correct

description 'Determines cookbooks that are safe to shake out of metadata.rb'
needs_rules %w{
  MetadatarbExists
  AttributeExists
  LibraryExists
  ResourceExists
  ProviderExists
  RecipeExists
  ExplicitMetadataDepends
  IncludeRecipeLiterals
  IncludeRecipeDynamic
  RoleRunListRecipes
  CookbookPropertyLiterals
}

def determine_role_referenced_cookbooks
  recipes = Set.new
  @kb.roles.each do |_, metadata|
    metadata['RoleRunListRecipes'].each do |recipe|
      recipes << recipe
    end
  end
  Set.new(recipes.map { |x| x.gsub(/::.*/, '') }).each do |cb|
    @kb.cookbooks[cb]['role_referenced_cookbook'] = true
  end
end

def determine_cookbook_property_referenced_cookbooks
  cookbooks = Set.new
  @kb.recipes.each do |_, metadata|
    metadata['CookbookPropertyLiterals'].each do |cookbook|
      cookbooks << cookbook
    end
  end
  cookbooks.each do |cb|
    @kb.cookbooks[cb]['cookbook_property_referenced_cookbook'] = true
  end
  cookbooks.to_a.sort
end

def determine_recipe_only_cookbooks
  cookbooks = Set.new(@kb.cookbooks.keys)
  cookbooks.subtract(Set.new(@kb.attributes.map { |_, c| c['cookbook'] }))
  cookbooks.subtract(Set.new(@kb.libraries.map { |_, c| c['cookbook'] }))
  cookbooks.subtract(Set.new(@kb.resources.map { |_, c| c['cookbook'] }))
  cookbooks.subtract(Set.new(@kb.providers.map { |_, c| c['cookbook'] }))
  cookbooks.each do |cb|
    @kb.cookbooks[cb]['recipe_only_cookbook'] = true
  end
  cookbooks.to_a.sort
end

def determine_cookbooks_using_dependency
  @kb.cookbooks.each do |cb, m|
    m['dependencies'].each do |dep|
      @kb.cookbooks[dep]['cookbooks_using_as_dependency'] ||= Set.new
      @kb.cookbooks[dep]['cookbooks_using_as_dependency'] << cb
    end
  end
end

def determine_cookbook_dependencies
  @kb.cookbooks.each do |cb, m|
    metadata_hash = @kb.metadatarbs["#{cb}::metadata.rb"] || @kb.metadatajsons["#{cb}::metadata.json"]
    m['dependencies'] ||= metadata_hash['ExplicitMetadataDepends'].flatten.to_set
  end
end

def determine_explicitly_included_cookbooks
  @kb.recipes.select do |_, m|
    next unless m['IncludeRecipeLiterals']

    @kb.cookbooks[m['cookbook']]['explicitly_included_cookbooks'] ||= Set.new
    @kb.cookbooks[m['cookbook']]['explicitly_included_cookbooks'] += m['IncludeRecipeLiterals'].flatten.map do |x|
      x.gsub(/::.*/, '')
    end
  end
end

# Cookbooks with dynamic recipe inclusion can't be safely shaken :-(
def determine_cookbooks_with_dynamic_recipe_inclusion
  @kb.recipes.select do |_, m|
    if m['IncludeRecipeDynamic']
      @kb.cookbooks[m['cookbook']]['dynamic_recipe_inclusion'] = true
    end
  end
end

def shakee_debug(shakee, msg)
  # It's not always clear why cookbooks aren't showing up in the results
  # (usually a result of convoluted dependency chains), so this variable is for
  # debugging until there's granular logging facility support in Bookworm
  debug = false
  puts "SHAKEE #{shakee}: #{msg}" if debug
end

def to_an_array
  investigate = []

  determine_role_referenced_cookbooks
  determine_cookbook_dependencies
  determine_cookbooks_using_dependency
  determine_explicitly_included_cookbooks
  determine_cookbooks_with_dynamic_recipe_inclusion

  # Save the values
  crpc = determine_cookbook_property_referenced_cookbooks
  roc = Set.new(determine_recipe_only_cookbooks)

  @kb.cookbooks.sort_by { |x| x[0] }.each do |shakee, smd| # smd - Shakee cookbook's bookworm metadata
    # No dependencies to shake, move along
    if smd['dependencies'].empty?
      shakee_debug shakee, 'does not have dependencies'
      next
    end

    # If a cookbook has a dynamic include_recipe call, we can't safely assume
    # what it calls, so we'll need to skip :-(
    if smd['dynamic_recipe_inclusion']
      shakee_debug(shakee, 'is a cookbook with dynamic recipe inclusion') if smd['dynamic_recipe_inclusion']
      next
    end

    # Copy dependencies of cookbook
    shakee_deps = smd['dependencies'].dup

    # Remove non-recipe-only cookbooks
    shakee_deps &= roc
    next if shakee_deps.empty?

    # Remove cookbooks referenced by another cookbook through the
    # `cookbook` property seen in cookbook_file/template/remote_directory
    # resources
    shakee_deps.subtract(crpc)
    next if shakee_deps.empty?

    # Remove cookbooks that have an explicit include_recipe reference
    shakee_debug shakee, "explicitly included cookbooks:\n#{smd['explicitly_included_cookbooks'].join("\n")}"

    shakee_deps.subtract(smd['explicitly_included_cookbooks'])
    next if shakee_deps.empty?

    shakee_debug(shakee, 'is a role referenced cookbook') if smd['role_referenced_cookbook']
    shakee_debug(shakee, 'is also a recipe-only cookbook') if smd['recipe_only_cookbook']

    # Does the shakee have the dependencies of the dependencies?
    # This step is necessary to ensure that the cookbook load order isn't
    # disrupted by transitive dependencies getting juggled around
    # See https://github.com/chef/chef/blob/4ce99c419028c169aeb3e68ec954b79f20e654c5/lib/chef/run_context/cookbook_compiler.rb#L112-L127
    # and https://github.com/chef/chef/blob/4ce99c419028c169aeb3e68ec954b79f20e654c5/lib/chef/run_context/cookbook_compiler.rb#L395-L408
    # and https://github.com/chef/chef/blob/4ce99c419028c169aeb3e68ec954b79f20e654c5/lib/chef/run_context/cookbook_compiler.rb#L438-L443
    shakee_deps.each do |dep|
      if @kb.cookbooks[dep]['dependencies'].subset? smd['dependencies']
        investigate << [shakee, dep]
        shakee_debug shakee, "can likely remove #{dep}"
      else
        shakee_debug shakee, "DEP #{dep} also wants #{@kb.cookbooks[dep]['dependencies'] - smd['dependencies']}"
        # If this cookbook isn't referenced by a role, we can easily assume that
        # any cookbook that uses the shakee as a dependency has already loaded
        # the cookbooks as well.
        unless smd['role_referenced_cookbook']
          # This isn't a role-referenced cookbook, so we can try adding "parents" deps to the shakee dep list
          if smd['cookbooks_using_as_dependency']&.all? do |parent_cb|
            @kb.cookbooks[dep]['dependencies'].subset?((smd['dependencies']+@kb.cookbooks[parent_cb]['dependencies']))
          end
            investigate << [shakee, dep]
            shakee_debug shakee, "can likely remove #{dep} with parent cookbook dependencies in place"
          end
        end
      end
    end
  end
  investigate
end

def to_a_string
  buffer = ''
  buffer << "WARNING: CookbookDepShaker results should *always* be reviewed for correctness\n"
  to_an_array.each do |shakee, dep|
    buffer << "Cookbook #{shakee} - can likely remove #{dep}\n"
  end
  buffer
end

def output
  to_a_string
end
