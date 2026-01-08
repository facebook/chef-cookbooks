# Copyright (c) Meta Platforms, Inc. and affiliates.
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

require 'chefspec'
require_relative '../libraries/helpers.rb'

def mock_which(choco_path)
  allow_any_instance_of(Chef::Mixin::Which).
    to receive(:which).with('choco.exe').and_return(choco_path)
end

def mock_file(path, status)
  allow(::File).
    to receive(:exist?).
    with(path).
    and_return(status)
end

describe FB::Choco::Helpers do
  let(:helpers) { extend FB::Choco::Helpers }

  context 'When choco.exe is found in $env:PATH' do
    before do
      mock_which('C:\\ProgramData\\chocolatey\\bin/choco.exe')
    end
    it 'should return C:\\ProgramData\\chocolatey\\bin/choco.exe' do
      expect(helpers.get_choco_bin).
        to eql('C:\\ProgramData\\chocolatey\\bin/choco.exe')
    end
  end
  context 'When choco.exe is NOT found in $env:PATH and exists on disk' do
    before do
      mock_which(nil)
      mock_file('C:\\ProgramData\\Chocolatey\\bin\\choco.exe', true)
    end
    it 'should return C:\\ProgramData\\Chocolatey\\bin\\choco.exe' do
      expect(helpers.get_choco_bin).
        to eql('C:\\ProgramData\\Chocolatey\\bin\\choco.exe')
    end
  end
  context 'When choco.exe cannot be found anywhere' do
    before do
      mock_which(nil)
      mock_file('C:\\ProgramData\\Chocolatey\\bin\\choco.exe', false)
    end
    it 'should return nil' do
      expect(helpers.get_choco_bin).to eql(nil)
    end
  end
end
