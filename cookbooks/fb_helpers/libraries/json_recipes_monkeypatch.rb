#
# Monkey patches to bring https://github.com/chef/chef/pull/15094
# into older Chef
#
if Chef::VERSION < '16'
  # The `from_hash` functionality that YAML and JSON recipes use was added in Chef 16
  Chef::Log.warn('[fb_helpers] Not loading JSON recipe monkeypatch,')
  Chef::Log.warn('[fb_helpers] unsupported below Chef client version 16')
  return
elsif Chef::VERSION >= '19.1.53' || Chef::VERSION >= '18.7.28'
  Chef::Log.info('[fb_helpers] Not loading JSON recipe monkeypatch,')
  Chef::Log.info("[fb_helpers] since it's already in this version of Chef")
  return
end
Chef::Log.info('[fb_helpers] Loading JSON recipe monkeypatch')

# rubocop:disable all
class Chef
  class CookbookVersion
    # Note - this is the only modified method on the upstream release
    def load_recipe(recipe_name, run_context)
      if recipe_filenames_by_name.key?(recipe_name)
        load_ruby_recipe(recipe_name, run_context)
      elsif recipe_yml_filenames_by_name.key?(recipe_name)
        load_yml_recipe(recipe_name, run_context)
      elsif recipe_json_filenames_by_name.key?(recipe_name)
        load_json_recipe(recipe_name, run_context)
      else
        raise Chef::Exceptions::RecipeNotFound, "could not find recipe #{recipe_name} for cookbook #{name}"
      end
    end

    def recipe_json_filenames_by_name
      @recipe_json_filenames_by_name ||= begin
        name_map = json_filenames_by_name(files_for("recipes"))
        root_alias = cookbook_manifest.root_files.find { |record|
          record[:name] == "root_files/recipe.json"
        }
        if root_alias
          Chef::Log.error("Cookbook #{name} contains both recipe.json and recipes/default.json, ignoring recipes/default.json"
) if name_map["default"]
          name_map["default"] = root_alias[:full_path]
        end
        name_map
      end
    end

    def load_json_recipe(recipe_name, run_context)
      Chef::Log.trace("Found recipe #{recipe_name} in cookbook #{name}")
      recipe = Chef::Recipe.new(name, recipe_name, run_context)
      recipe_filename = recipe_json_filenames_by_name[recipe_name]

      unless recipe_filename
        raise Chef::Exceptions::RecipeNotFound, "could not find #{recipe_name} files for cookbook #{name}"
      end

      recipe.from_json_file(recipe_filename)
      recipe
    end

    # Filters JSON files from the superset of provided files.
    def json_filenames_by_name(records)
      records.select { |record| record[:name].end_with?(".json") }.inject({}) { |memo, record| memo[File.basename(record[:name], ".json")] = record[:full_path]; memo }
    end

  end

  class Recipe
    def from_json_file(filename)
      self.source_file = filename
      if File.file?(filename) && File.readable?(filename)
        json_contents = IO.read(filename)
        from_json(json_contents)
      else
        raise IOError, "Cannot open or read file '#{filename}'!"
      end
    end

    def from_json(string)
      res = JSONCompat.from_json(string)
      unless res.is_a?(Hash) && res.key?("resources")
        raise ArgumentError, "JSON recipe '#{source_file}' must contain a top-level 'resources' hash"
      end

      from_hash(res)
    end
  end
end

