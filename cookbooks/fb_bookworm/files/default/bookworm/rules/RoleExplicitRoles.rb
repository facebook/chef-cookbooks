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
description 'Scrapes explicit roles in a role files run list'
keys ['role']

def_node_matcher :role_run_list, '`(send nil? :run_list (str $_)*)'

def output
  arr = role_run_list @metadata['ast']
  roles = []
  arr&.each do |item|
    roles << item if item.start_with? 'role['
  end
  # TODO(dcrosby) better regex here
  roles.map! { |x| x.gsub(/^role\[/, '') }
  roles.map { |x| x.gsub(/\]$/, '') }
end
