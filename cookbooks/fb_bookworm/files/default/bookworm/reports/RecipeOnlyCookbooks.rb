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
description 'Determines all cookbooks that do not evaluate Ruby code on load'
needs_rules %w{
  MetadatarbExists
  AttributeExists
  LibraryExists
  ResourceExists
  ProviderExists
}

def to_a
  cookbooks = Set.new(@kb.cookbooks.keys)
  cookbooks.subtract(Set.new(@kb.attributes.map { |_, c| c['cookbook'] }))
  cookbooks.subtract(Set.new(@kb.libraries.map { |_, c| c['cookbook'] }))
  cookbooks.subtract(Set.new(@kb.resources.map { |_, c| c['cookbook'] }))
  cookbooks.subtract(Set.new(@kb.providers.map { |_, c| c['cookbook'] }))
  cookbooks.to_a.sort
end

def output
  to_a
end
