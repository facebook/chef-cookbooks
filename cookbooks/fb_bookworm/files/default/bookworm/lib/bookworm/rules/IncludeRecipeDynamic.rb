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
description 'Extracts recipes that do not use include_recipe with a string literal'
keys ['recipe']

def_node_search :include_recipe_dynamic, '`(send nil? :include_recipe $_)'

def output
  include_recipe_dynamic(@metadata['ast']).any? do |x|
    !(x.is_a?(RuboCop::AST::StrNode) && x.str_type?)
  end
end
