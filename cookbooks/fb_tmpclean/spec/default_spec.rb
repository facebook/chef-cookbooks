# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates.
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

require './spec/spec_helper'

recipe 'fb_tmpclean::default', :unsupported => [:mac_os_x] do |tc|
  # The tmpwatch cron must never delete systemd's PrivateTmp= directories:
  # a long-running unit whose /tmp/systemd-private-* directory is deleted
  # can no longer create files in its private /tmp, and its ExecStop*
  # commands fail to spawn (226/NAMESPACE).
  systemd_private_exclude = %r{-X '/tmp/systemd-private-\*'}

  context 'on a RHEL-family host' do
    let(:chef_run) do
      tc.chef_run(:step_into => ['include_recipe_at_converge_time'])
    end

    it 'excludes systemd private tmp dirs from /tmp cleaning' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_tmpclean']['directories']['/tmp'] = '2d'
      end
      expect(chef_run).to render_file('/etc/cron.daily/tmpwatch').
        with_content(systemd_private_exclude)
    end
  end

  context 'on a Fedora host' do
    # Fedora reports platform_family 'fedora', not 'rhel'. The recipe already
    # treats both families as tmpwatch platforms; the attributes must too, or
    # Fedora hosts get NO excludes at all. The platform facts have to be set
    # in the runner block: attribute files are evaluated before the converge
    # block runs.
    let(:chef_run) do
      tc.chef_run(:step_into => ['include_recipe_at_converge_time']) do |node|
        node.automatic['platform'] = 'fedora'
        node.automatic['platform_family'] = 'fedora'
      end
    end

    it 'excludes systemd private tmp dirs from /tmp cleaning' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_tmpclean']['directories']['/tmp'] = '2d'
      end
      expect(chef_run).to render_file('/etc/cron.daily/tmpwatch').
        with_content(systemd_private_exclude)
    end

    it 'keeps the X11 socket dir exclusions too' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_tmpclean']['directories']['/tmp'] = '2d'
      end
      expect(chef_run).to render_file('/etc/cron.daily/tmpwatch').
        with_content(%r{-X '/tmp/\.X11-unix'})
    end
  end
end
