# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates
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
require_relative 'spec_helper'
require 'open3'
require 'tmpdir'

describe 'bookworm invocation' do
  let(:ruby) { '/opt/chef-workstation/embedded/bin/ruby' }
  let(:bookworm_rb) { File.expand_path('../bookworm.rb', __dir__) }

  it 'runs when invoked via absolute path to bookworm.rb' do
    stdout, stderr, status = Open3.capture3(ruby, bookworm_rb, '--list-reports')
    expect(status.exitstatus).to eq(0),
                                 "Expected exit 0 but got #{status.exitstatus}. " +
                                 "stdout: #{stdout}\nstderr: #{stderr}"
    expect(stdout).not_to be_empty
  end

  it 'lists reports without source_dirs configured' do
    stdout, stderr, status = Open3.capture3(
      { 'HOME' => Dir.mktmpdir },
      ruby, bookworm_rb, '--list-reports'
    )
    expect(status.exitstatus).to eq(0),
                                 "Expected exit 0 but got #{status.exitstatus}. " +
                                 "stdout: #{stdout}\nstderr: #{stderr}"
    expect(stdout).not_to be_empty
  end

  it 'lists rules without source_dirs configured' do
    stdout, stderr, status = Open3.capture3(
      { 'HOME' => Dir.mktmpdir },
      ruby, bookworm_rb, '--list-rules'
    )
    expect(status.exitstatus).to eq(0),
                                 "Expected exit 0 but got #{status.exitstatus}. " +
                                 "stdout: #{stdout}\nstderr: #{stderr}"
    expect(stdout).not_to be_empty
  end
end
