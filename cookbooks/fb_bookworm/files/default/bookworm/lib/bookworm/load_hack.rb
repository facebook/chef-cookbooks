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

# TODO: This is gross, and I seem to recall there was some way to get a gem's
# library directory, but this should work for now.
module Bookworm
  BUILTIN_REPORTS_DIR = "#{__dir__}/reports/".freeze
  BUILTIN_RULES_DIR = "#{__dir__}/rules/".freeze
end
