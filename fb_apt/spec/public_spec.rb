# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

# we know relative_requires is bad, but it allows us to handle pathing
# differences between internal repo and github
require_relative '../libraries/default'

describe 'FB::Apt' do
  control = <<-eos
// This file is maintained by Chef. Do not edit, all changes will be
// overwritten. See fb_apt/README.md

Acquire::http {
  Proxy "http://myproxy:3412";
};
APT {
  Default-Release "stable";
  Cache-Limit "10000000";
};
  eos
  # remove trailing newline added by the heredoc
  control.chomp!

  it 'should generate apt.conf' do
    generated = <<-eos
// This file is maintained by Chef. Do not edit, all changes will be
// overwritten. See fb_apt/README.md
    eos
    {
      'Acquire::http' => {
        'Proxy' => 'http://myproxy:3412',
      },
      'APT' => {
        'Default-Release' => 'stable',
        'Cache-Limit' => 10000000,
      },
    }.each do |key, val|
      generated += FB::Apt.gen_apt_conf_entry(key, val)
    end
    expect(generated).to eq(control)
  end
end
