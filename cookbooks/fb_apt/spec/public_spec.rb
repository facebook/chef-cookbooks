# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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

# we know relative_requires is bad, but it allows us to handle pathing
# differences between internal repo and github
require_relative '../libraries/default'

describe 'FB::Apt' do
  control = <<-EOS
// This file is maintained by Chef. Do not edit, all changes will be
// overwritten. See fb_apt/README.md

Acquire::http {
  Proxy "http://myproxy:3412";
};
APT {
  Default-Release "stable";
  Cache-Limit "10000000";
};
  EOS
  # remove trailing newline added by the heredoc
  control.chomp!

  it 'should generate apt.conf' do
    generated = <<-EOS
// This file is maintained by Chef. Do not edit, all changes will be
// overwritten. See fb_apt/README.md
    EOS
    {
      'Acquire::http' => {
        'Proxy' => 'http://myproxy:3412',
      },
      'APT' => {
        'Default-Release' => 'stable',
        'Cache-Limit' => 10000000,
      },
    }.each do |key, val|
      generated += FB::Apt._gen_apt_conf_entry(key, val)
    end
    expect(generated).to eq(control)
  end
end
