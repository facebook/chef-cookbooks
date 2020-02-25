# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Facebook, Inc.
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

require 'chefspec'
require_relative '../libraries/fb_grubby_helpers'

describe FB::Grubby do
  context 'When computing grubby commands' do
    let(:grubby) { Class.new { extend FB::Grubby } }
    it 'should only add missing arguments' do
      expect(grubby.get_add_args(
               ['rhgb', 'quiet'].to_set,
               ['rhgb', 'LANG=en_US.UTF-8'].to_set,
      )).to eq(['LANG=en_US.UTF-8'].to_set)
    end
    it 'should only remove existing arguments' do
      expect(grubby.get_rm_args(
               ['rhgb', 'quiet'].to_set,
               ['quiet', 'LANG=en_US.UTF-8'].to_set,
      )).to eq(['quiet'].to_set)
    end
  end
end
