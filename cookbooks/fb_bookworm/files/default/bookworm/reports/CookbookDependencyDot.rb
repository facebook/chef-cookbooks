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
description 'Determine cookbook dependencies from cookbook metadata.rb, output to Dot language'
needs_rules ['ExplicitMetadataDepends']

def to_s
  cookbook_deps = []
  @kb.metadatarbs.each do |x, metadata|
    metadata['ExplicitMetadataDepends'].each do |cb|
      cookbook_deps << [x.gsub(/:.*/, ''), cb]
    end
  end
  "digraph deps {\n#{cookbook_deps.map { |arr| arr.join('->') }.join("\n")}\n}"
end

def output
  to_s
end
