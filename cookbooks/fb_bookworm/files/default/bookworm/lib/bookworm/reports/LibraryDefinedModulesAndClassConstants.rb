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
description 'Get modules and classes constants that are explicitly defined in library files'
needs_rules ['LibraryDefinedClassConstants', 'LibraryDefinedModuleConstants']

def output
  buffer = ''
  buffer << "file\tmodules\tconstants\n"
  @kb.libraries.sort_by { |k, _| k }.each do |name, metadata|
    # buffer << name
    buffer << "#{name}:\t#{metadata['LibraryDefinedModuleConstants'].join(',')}" +
              "\t#{metadata['LibraryDefinedClassConstants'].join(',')}\n"
  end
  buffer
end
