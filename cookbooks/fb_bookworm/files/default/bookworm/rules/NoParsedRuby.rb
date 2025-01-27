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
description 'Ruby files which are empty, comments-only, ' +
            'or unparseable by RuboCop'
keys %w{
  attribute
  library
  metadatarb
  provider
  recipe
  resource
  role
}

# See note in crawler.rb about EMPTY_RUBOCOP_AST constant
def output
  @metadata['ast'] == Bookworm::Crawler::EMPTY_RUBOCOP_AST
end
