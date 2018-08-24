# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

provides :fb_launchd, :os => 'darwin'

default_action :run

def whyrun_supported?
  true
end

# Attributes that circumvent or defeat the purpose of using launchd as a node
# API. Blacklist them so that this blows up when they're used. If you really
# want to use these, just make a launchd resource instead.
BLACKLISTED_ATTRIBUTES = %w{
  label
  path
}.freeze

# Plist directories in which to search for managed jobs.
PLIST_DIRECTORIES = %w{
  /Library/LaunchAgents
  /Library/LaunchDaemons
}.freeze

action :run do
  # The prefix should look like a normal label without a trailing '.' and
  # *hopefully* no globs, but let's be on the safe side...
  prefix = Chef::Util::PathHelper.escape_glob(node['fb_launchd']['prefix'])
  if prefix.end_with?('.')
    fail "fb_launchd: prefix '#{prefix}' must not end with a trailing '.'"
  end

  # Delete old jobs first.
  managed_plists(prefix).each do |path|
    label = ::File.basename(path, '.plist')
    name = label.sub(prefix + '.', '')
    next if node['fb_launchd']['jobs'].include?(name)

    # Delete with 'path' specified to enforce that we delete the right one.
    Chef::Log.debug("fb_launchd: deleting #{label}")
    launchd_resource(label, :delete, { 'path' => path })
  end

  # Set up current jobs.
  node['fb_launchd']['jobs'].each do |name, attrs|
    if attrs.keys.any? { |k| BLACKLISTED_ATTRIBUTES.include?(k) }
      fail "fb_launchd[#{name}]: uses a blacklisted attribute (one of " +
        "#{BLACKLISTED_ATTRIBUTES}). If you want to use them, create a " +
        "'launchd' resource instead"
    end

    # Determine our label. The directory (/Library/LaunchDaemons or
    # /Library/LaunchAgents) is determined by the label + type (which defaults
    # to daemon if unspecified).
    label = "#{prefix}.#{name}"

    # Create resource
    launchd_resource(label, attrs.fetch('action', :enable), attrs)
  end
end

action_class do
  # Constructs a new launchd resource with label 'label' and action 'action'.
  # attrs is a Hash of key/value pairs of launchd attributes and their values.
  # Returns the new launchd resource.
  def launchd_resource(label, action, attrs = {})
    Chef::Log.debug(
      "fb_launchd: new launchd resource '#{label}' with action '#{action}' " +
      "and attributes #{attrs}",
    )
    return unless label

    res = launchd label do
      action action.to_sym
    end
    attrs.each do |attribute, value|
      next if attribute == 'action'
      res.send(attribute.to_sym, value)
    end

    res
  end

  # Finds any managed plists in the standard launchd directories with the
  # specified prefix. Returns a list of paths to the managed plists.
  def managed_plists(prefix)
    PLIST_DIRECTORIES.map do |dir|
      plist_glob = ::File.join(::File.expand_path(dir), "*#{prefix}*.plist")
      ::Dir.glob(plist_glob)
    end.flatten
  end
end
