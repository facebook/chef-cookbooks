# Copyright (c) 2021-present, Facebook, Inc.
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

recipe 'fb_dnf::packages', :supported => [:centos8] do |tc|
  let(:chef_run) do
    tc.chef_run(:step_into => ['include_recipe_at_converge_time'])
  end

  # The version-independent base plus the dnf (dnf4) stack, i.e. the branch
  # taken on everything except Fedora >= 41 / EL >= 11 / ELN.
  dnf_stack = %w{
    dnf-data
    libcomps
    libdnf
    libsolv
    python3-dnf
    python3-dnf-plugins-core
    python3-libcomps
    dnf
    dnf-plugins-core
    dnf-utils
  }

  # The version-independent base plus the dnf5 stack.
  dnf5_stack = %w{
    dnf-data
    libcomps
    libdnf
    libsolv
    python3-dnf
    python3-dnf-plugins-core
    python3-libcomps
    dnf5
    dnf5-plugins
  }

  context 'when manage_packages is true' do
    it 'installs the dnf package stack' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_dnf']['manage_packages'] = true
      end
      expect(chef_run).to install_package(dnf_stack)
      expect(chef_run).not_to install_package(dnf5_stack)
    end

    context 'on a dnf5 platform (fedora >= 41 / el >= 11 / eln)' do
      # The platform fork is evaluated at compile time, so the node predicate
      # must be stubbed on every Chef::Node instance before the converge.
      before(:each) do
        allow_any_instance_of(Chef::Node).to receive(:eln?).and_return(true)
      end

      it 'installs the dnf5 package stack' do
        chef_run.converge(described_recipe) do |node|
          node.default['fb_dnf']['manage_packages'] = true
        end
        expect(chef_run).to install_package(dnf5_stack)
        expect(chef_run).not_to install_package(dnf_stack)
      end
    end
  end

  context 'when manage_packages is false' do
    it 'does not install any dnf packages' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_dnf']['manage_packages'] = false
      end
      expect(chef_run).not_to install_package(dnf_stack)
      expect(chef_run).not_to install_package(dnf5_stack)
    end
  end
end
