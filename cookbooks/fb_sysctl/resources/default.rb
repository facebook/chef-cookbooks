# Copyright (c) 2018-present, Facebook, Inc.

unified_mode(false) if Chef::VERSION >= 18 # TODO(T144966423)
default_action :apply

def set_sysctl(node, name, val)
  s = shell_out("#{FB::Sysctl.binary_path(node)} -w #{name}=\"#{val}\"")
  s.error!
end

# Normally you'd expect to just run `sysctl -p` when you update the file.
# However, this isn't actually idempotent. It sets every single sysctl in
# /etc/sysctl.conf - even the ones that aren't changing... and some sysctls
# cause actions in the kernel upon writing (like dropping caches). We want
# to be fully idempotent and only set the things that have changed and honor
# the expectations the Chef users have around idempotency. So here we walk
# all of the ones we expect to be set and update only those that are not
# correct.
action :apply do
  bad_settings = FB::Sysctl.incorrect_settings(
    FB::Sysctl.current_settings(node),
    node['fb_sysctl'].to_hash,
  )
  unless bad_settings.empty?
    converge_by 'Converging sysctls' do
      messages = bad_settings.map do |k, v|
        "#{k} (#{v} -> #{node['fb_sysctl'][k]})"
      end
      Chef::Log.info(
        "fb_sysctl: Setting sysctls: #{messages.join(', ')}",
      )
      bad_settings.each_key do |k|
        set_sysctl(node, k, node['fb_sysctl'][k])
      end
    end
  end
end
