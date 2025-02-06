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
description 'Basic report to show extraction of description from roles'
needs_rules ['RoleName', 'RoleDescription']

def to_plain
  buffer = ''
  @kb.roles.sort_by { |k, _| k }.each do |name, metadata|
    # buffer << name
    buffer << "role: #{name} desc: #{metadata['RoleDescription']}\n"
  end
  buffer
end
