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
description 'Scrapes notifications from resources in recipe and resource files'
keys ['recipe', 'resource']

def_node_search :subscribes_property, '(send nil? ${:subscribes :notifies} (sym $_) $_ (sym $_)?)'

def output
  subscriptions = []
  subscribes_property(@metadata['ast']).each do |method, action, resources, timer|
    timer = timer[0] ? timer[0] : :delayed # handle optional timer, :delayed is default

    if resources.str_type?
      resources = [resources.value]
    elsif resources.array_type?
      resources = resources.children.map(&:value)
    else
      next
    end

    subscriptions << [method, action, resources, timer]
  end

  subscriptions
end
