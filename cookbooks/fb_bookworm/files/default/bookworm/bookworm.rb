#!/opt/chef-workstation/embedded/bin/ruby
# Copyright (c) 2024-present, Meta Platforms, Inc. and affiliates
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
#
# Wrapper so that we can have ruby load path hackery from the fb_bookworm cookbook
# I'd like to believe this won't be permanent, but these things last for years...

$LOAD_PATH.unshift("#{__dir__}/lib")
load "#{__dir__}/bin/bookworm"
