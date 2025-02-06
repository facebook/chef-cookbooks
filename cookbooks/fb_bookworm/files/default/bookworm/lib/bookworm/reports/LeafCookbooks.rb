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
description 'Determine all leaf cookbooks, where no other cookbook depends on it via metadata.rb'
needs_rules ['ExplicitMetadataDepends']

def to_a
  buffer = Set.new
  @kb.metadatarbs.each do |_, metadata|
    metadata['ExplicitMetadataDepends'].each do |cb|
      buffer << cb
    end
  end
  (@kb.cookbooks.keys.to_set - buffer).sort.to_a
end

def output
  to_a
end
