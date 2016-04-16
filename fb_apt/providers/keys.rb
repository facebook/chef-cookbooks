# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

def whyrun_supported?
  true
end

use_inline_resources

action :run do
  keyring = node['fb_apt']['keyring']
  keyserver = node['fb_apt']['keyserver']
  keys = node['fb_apt']['keys'].to_hash

  if keys && keyring
    cmd = Mixlib::ShellOut.new("LANG=C apt-key --keyring #{keyring} list")
    cmd.run_command
    # Note: we deliberately ignore errors here, as this will fail if the keyring
    # doesn't exist (e.g. because there are no keys yet).
    output = cmd.stdout.split("\n")
    Chef::Log.debug("apt-key output: #{output.join("\n")}")
    installed_keys = output.select { |x| x.start_with?('pub') }.map do |x|
      x[%r/pub.*\/(?<keyid>[A-Z0-9]*)/, 'keyid']
    end
    Chef::Log.info("Installed keys: #{installed_keys.join(', ')}")

    # Process keys to add
    keys.each do |keyid, key|
      if installed_keys.include?(keyid)
        Chef::Log.debug("Skipping keyid #{keyid} as it's already registered")
      else
        Chef::Log.debug("Processing new keyid #{keyid}")
        if key
          execute "add key for #{keyid} to APT" do
            command "echo '#{key}' | apt-key add -"
          end
        elsif keyserver
          execute "fetch and add key for keyid #{keyid} to APT" do
            command "apt-key adv --keyserver #{keyserver} --recv #{keyid}"
          end
        else
          fail "Cannot fetch key for #{keyid} as keyserver is not defined"
        end
      end
    end

    # Process keys to remove
    installed_keys.each do |keyid|
      if keys.include?(keyid)
        Chef::Log.debug("Not deleting added keyid #{keyid}")
      else
        execute "delete key for #{keyid} from APT" do
          command "apt-key del #{keyid}"
        end
      end
    end
  end
end
