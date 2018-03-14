# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

def runcmd(cmd, dest)
  Chef::Log.debug("fb_rsync[#{dest}]: Running command: #{cmd}")
  # Throw normal errors except on 25 which is a max-delete limit error
  s = Mixlib::ShellOut.new(cmd, :returns => [0, 25])
  s.run_command.error!
  Chef::Log.debug("STDOUT:\n#{s.stdout}")
  Chef::Log.debug("STDERR:\n#{s.stderr}")
  return s.exitstatus
end

action :sync do
  src_i = new_resource.source
  if src_i =~ /^::/
    unless node['fb_rsync']['rsync_server']
      fail 'fb_rsync: cannot sync as neither rsync_server nor source are set.'
    end
    src = "#{node['fb_rsync']['rsync_server']}#{src_i}"
  else
    src = src_i
  end

  # convenience vars
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
      Chef::Log.info("Refusing to continue after running command: #{cmd}")
      fail FB::Rsync::MaxDeleteLimit, 'Rsync will result in deleting more ' +
          "than --max-delete limit (#{maxdel}), cowardly refusing to continue"
    end
  end

  # Actually run the rsync
  cmd = "rsync #{opts} #{src} #{dest}"
  status = runcmd(cmd, dest)

  # We always run the rsync and there's no way to know if it changed anything
  # so if we got this far we have to assume we did
  new_resource.updated_by_last_action(true)
  Chef::Log.info("fb_rsync[#{dest}]: Rsync complete")

  # Be extra paranoid in case we somehow hit maxdeletes even though we tried to
  # check with a dryrun to prevent that on the real run
  if status == 25
    fail FB::Rsync::MaxDeleteLimit, 'Hit --max-delete limit during rsync. ' +
        "Deleted #{maxdel} items before stopping"
  end
end
