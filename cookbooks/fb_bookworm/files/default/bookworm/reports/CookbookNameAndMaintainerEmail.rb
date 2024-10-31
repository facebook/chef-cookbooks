# Copyright (c) 2022-present, Meta, Inc.
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
description 'Cross-reference the cookbook name to the maintainer_email in a CSV fashion'
needs_rules ['MetadatarbAttributeLiterals']

def to_a
  buffer = Set.new
  @kb.metadatarbs.each do |_, metadata|
    cb = metadata['MetadatarbAttributeLiterals']
    buffer << "#{cb[:name]},#{cb[:maintainer_email]}"
  end
  buffer.sort.to_a
end

def output
  to_a
end
