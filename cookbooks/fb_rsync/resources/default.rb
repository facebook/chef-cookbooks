# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
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

property :destination, String, :name_property => true, :required => true
property :source, String, :required => true
property :sharddelete, [TrueClass, FalseClass], :default => false
property :sharddeleteexcluded, [TrueClass, FalseClass], :default => false
property :extraopts, String, :default => ''
property :partial, [TrueClass, FalseClass], :default => true
property :timeout, Integer, :default => 60
property :maxdelete, Integer, :default => 100

action_class do
  def runcmd(cmd, dest)
    Chef::Log.debug("fb_rsync[#{dest}]: Running command: #{cmd}")
    # Throw normal errors except on 25 which is a max-delete limit error
    s = Mixlib::ShellOut.new(cmd, :returns => [0, 25])
    s.run_command.error!
    Chef::Log.debug("fb_rsync[#{dest}]: STDOUT:\n#{s.stdout}")
    Chef::Log.debug("fb_rsync[#{dest}]: STDERR:\n#{s.stderr}")
    s.exitstatus
  end
end

action :sync do
  # convenience vars
  src = FB::Rsync.determine_src(new_resource.source, node)
  dest = new_resource.destination
  exopts = new_resource.extraopts
  maxdel = new_resource.maxdelete
  delexclude = new_resource.sharddeleteexcluded
  dodelete = false

  # Set some basic options to build on
  opts = '-avz --partial --partial-dir=.rsync-partial ' +
      "--timeout=#{new_resource.timeout}"

  if new_resource.sharddelete
    deletehour = node.get_flexible_shard(24)

    if deletehour == Time.at(node['ohai_time']).hour
      Chef::Log.info("fb_rsync[#{dest}]: Sharded deletes will happen " +
          'on this run')
      if delexclude
        # delete-excluded implies delete so we only need one or the other
        opts += ' --delete-excluded'
      else
        opts += ' --delete'
      end
      # maxdel can be nil if someone really wants to turn it off
      opts += " --max-delete=#{maxdel}" if maxdel
      dodelete = true
    else
      Chef::Log.info("fb_rsync[#{dest}]: Skipping deletes because our " +
          "shard only deletes during hour #{deletehour}")
    end
  end

  # Add the user's extra opts. God help them.
  opts += " #{exopts}" unless exopts.empty?

  # If we plan to delete with maxdelete, we need to dryrun because we won't
  # delete anything if it'll result in a partial delete due to maxdelete setting
  if dodelete && maxdel
    cmd = "rsync #{opts} --dry-run #{src} #{dest}"
    status = runcmd(cmd, dest)
    if status == 25
      # Echo the command in the log at info level so folks can easily find what
      # needs deleting while troubleshooting outside the sharddelete hour
      Chef::Log.info(
        "fb_rsync[#{dest}]: Refusing to continue after running command: #{cmd}",
      )
      fail FB::Rsync::MaxDeleteLimit, "fb_rsync[#{dest}]: Rsync will result " +
        "in deleting more than --max-delete limit (#{maxdel}), cowardly " +
        'refusing to continue.'
    end
  end

  # Actually run the rsync
  rsync_cmd = "rsync #{opts} #{src} #{dest}"
  Chef::Log.debug("fb_rsync: Running rsync cmd: #{rsync_cmd}")
  execute "rsync #{dest}" do
    command rsync_cmd
    action :run
  end

  # We always run the rsync and there's no way to know if it changed anything
  # so if we got this far we have to assume we did
  Chef::Log.info("fb_rsync[#{dest}]: Rsync complete")
end
