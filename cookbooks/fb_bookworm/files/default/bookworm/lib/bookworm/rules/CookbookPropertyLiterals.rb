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
description 'Extracts cookbooks referenced by the cookbook property common with file resources'
keys ['recipe']

def_node_search :resource_blocks, '`(block (send nil? {:cookbook_file :template :remote_directory} _) (args) $...)'

def_node_search :cookbook_literal, '`(send nil? :cookbook (:str $_))'

def to_a
  arr = []
  resource_blocks(@metadata['ast']).each do |res|
    # We've got a resource block, check for cookbook property
    res.each do |r|
      cookbook_literal(r).each do |prop|
        arr << prop
      end
    end
  end
  return [] if arr.empty?
  arr.uniq!
  arr.sort!
end
