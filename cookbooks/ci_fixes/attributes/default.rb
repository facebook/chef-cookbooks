# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2020-present, Facebook, Inc.
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

# monkeypatch for https://github.com/chef/ohai/pull/1476
if FB::Version.new(Chef::VERSION) < FB::Version.new('16.2.2')
  Chef::Log.debug('ci_fixes: applying virtualization monkeypatch')

  if File.exist?('/proc/self/cgroup')
    cgroup_content = File.read('/proc/self/cgroup')
    if cgroup_content =~ %r{^\d+:[^:]*:/(lxc|docker)/.+$} ||
      cgroup_content =~ %r{^\d+:[^:]*:/[^/]+/(lxc|docker)-?.+$}
      Chef::Log.info(
        'Plugin Virtualization Monkeypatch: /proc/self/cgroup indicates ' +
        "#{$1} container. Detecting as #{$1} guest",
      )
      node.automatic['virtualization']['system'] = $1 # ~FC047
      node.automatic['virtualization']['role'] = 'guest' # ~FC047
      node.automatic['virtualization']['systems'][$1.to_s] = 'guest' # ~FC047
    end
  end
else
  Chef::Log.warn('ci_fixes: clean up the virtualization monkeypatch!')
end
