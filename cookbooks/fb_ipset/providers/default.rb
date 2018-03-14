# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

use_inline_resources

def ipset_save(state_file)
  ipset_save_output = Mixlib::ShellOut.new('ipset save')
  ipset_save_output.run_command.error!

  file state_file do
    owner 'root'
    group 'root'
    mode '0600'
    content ipset_save_output.stdout
  end
end

action :update do
  existing_ipsets = FB::IPset.get_existing_ipsets
  expected_ipsets = node['fb_ipset']['sets'].to_hash

  # all ipsets should contain those keys for the comparison to be correct
  required_keys = ['type', 'family', 'hashsize', 'maxelem', 'members'].to_set
  expected_ipsets.each do |name, attributes|
    if attributes.keys.to_set != required_keys
      fail "Set #{name} should contain #{required_keys.to_a} keys"
    end
  end

  expected_ipsets.each do |setname, expected_set|
    unless existing_ipsets[setname]
      Chef::Log.info("fb_ipset[#{setname}]: Creating set")

      converge_by "Creating set #{setname}" do
        FB::IPset.ipset_to_cmds(setname, expected_set).each do |cmd|
          Mixlib::ShellOut.new(cmd).run_command.error!
        end
      end

      next
    end

    existing_set = existing_ipsets.delete(setname)
    existing_set['members'] = existing_set['members'].sort
    expected_set['members'] = expected_set['members'].sort

    if existing_set == expected_set
      next
    end

    Chef::Log.info("ipset[#{setname}]: Updating set")
    Chef::Log.debug("ipset[#{setname}]: old: #{existing_set.to_a.sort}")
    Chef::Log.debug("ipset[#{setname}]: new: #{expected_set.to_a.sort}")

    # create the replacement ipset
    new_name = "#{setname}NEW"
    cmds = FB::IPset.ipset_to_cmds(new_name, expected_set)

    # swap and cleanup
    cmds << "ipset swap #{new_name} #{setname}"
    cmds << "ipset flush #{new_name}"
    cmds << "ipset destroy #{new_name}"

    # run the actual commands
    converge_by "Create and swap #{setname}" do
      cmds.each do |cmd|
        Mixlib::ShellOut.new(cmd).run_command.error!
      end
    end
  end

  ipset_save new_resource.state_file || node['fb_ipset']['state_file']
end

action :cleanup do
  existing_ipsets = FB::IPset.get_existing_ipsets.keys.to_set
  expected_ipsets = node['fb_ipset']['sets'].keys.to_set

  (existing_ipsets - expected_ipsets).each do |setname|
    Chef::Log.info("fb_ipset[#{setname}]: Set not defined. Removing")
    cmd = "ipset destroy #{setname}"

    converge_by "Delete #{setname}" do
      r = Mixlib::ShellOut.new(cmd).run_command
      r.error!
    end
  end

  ipset_save new_resource.state_file || node['fb_ipset']['state_file']
end
