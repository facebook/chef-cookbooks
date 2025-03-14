# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates
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

# Formats error message to add link to the rules
def fb_msg(msg)
  "#{msg} (https://github.com/facebook/chef-cookbooks)".freeze
end

# Predefine modules for compact style, cannot be compact
module RuboCop # rubocop:disable Chef/Meta/CookstyleCompactClassStyle
  module Cop
    module Chef
      module Meta
        class Base < RuboCop::Cop::Base
          prepend RuboCop::Cop
        end
      end
    end
  end
end

cops = Dir.glob("#{__dir__}/*.rb", :base => __dir__)
cops.delete_if { |f| f.end_with?('helpers.rb') }
cops.each do |f|
  require_relative f
end
