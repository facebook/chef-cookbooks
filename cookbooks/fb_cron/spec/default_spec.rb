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

require './spec/spec_helper.rb'

recipe 'fb_cron::default' do |tc|
  let(:chef_run) { tc.chef_run }

  it 'should render basic crontab' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_cron']['jobs']['do_this_thing'] = {
        'time' => '1 2 3 4 5',
        'user' => 'apache',
        'command' => '/usr/local/bin/foo.php',
      }
      node.default['fb_cron']['jobs']['comment_special'] = {
        'time' => '1 2 3 4 5',
        'user' => 'apache',
        'command' => '/usr/local/bin/foo.php',
        'comment' => 'a very useful comment',
      }
    end

    expect(chef_run).to render_file('/etc/cron.d/fb_crontab').with_content(
      tc.fixture('fb_crontab'),
    )
  end

  it 'should render crontab with mailto' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_cron']['jobs']['do_this_thing'] = {
        'time' => '2 1 5 4 3',
        'user' => 'root',
        'command' => '/usr/local/bin/foo.php',
        'mailto' => 'noreply@fb.com',
      }
    end

    expect(chef_run).to render_file('/etc/cron.d/fb_crontab').with_content(
      tc.fixture('fb_crontab_mailto'),
    )
  end

  it 'should render crontab with more than one job' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_cron']['jobs']['do_this_thing'] = {
        'time' => '* 1 * 2 *',
        'user' => 'hank',
        'command' => '/usr/local/bin/foo.php',
      }
      node.default['fb_cron']['jobs']['do_this_other_thing'] = {
        'time' => '1 * 3 * 5',
        'user' => 'fred',
        'command' => '/usr/local/bin/bar.php',
        'mailto' => 'noreply@fb.com',
      }
    end

    expect(chef_run).to render_file('/etc/cron.d/fb_crontab').with_content(
      tc.fixture('fb_crontab_several'),
    )
  end

  it 'should render anacrontab on appropriate platforms' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_cron']['anacrontab']['environment'] = {
        'shell' => '/bin/bash',
        'path' => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/fake',
        'mailto' => 'noreply@fb.com',
        'random_delay' => '8',
        'start_hours_range' => '2-3',
      }
    end

    if tc.platform.to_s.start_with?('centos')
      expect(chef_run).to render_file('/etc/anacrontab').with_content(
        tc.fixture('anacrontab'),
      )
    else
      expect(chef_run).to_not render_file('/etc/anacrontab')
    end
  end
end
