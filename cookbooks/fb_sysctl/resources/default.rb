actions [:apply]
default_action :apply

def set_sysctl(name, val)
  s = Mixlib::ShellOut.new("/usr/sbin/sysctl -w #{name}=\"#{val}\"").run_command
  return !s.error?
end

action :apply do
  bad_settings = FB::Sysctl.incorrect_settings(
    FB::Sysctl.current_settings,
    node['fb_sysctl'].to_hash,
  )
  unless bad_settings.empty? # ~FC023
    converge_by 'Converging sysctls' do
      messages = bad_settings.map do |k, v|
        "#{k} (#{v} -> #{node['fb_sysctl'][k]})"
      end
      Chef::Log.info(
        "fb_sysctl: Setting sysctls: #{messages.join(', ')}",
      )
      failed_settings = []
      bad_settings.keys.each do |k|
        unless set_sysctl(k, node['fb_sysctl'][k])
          failed_settings << k
        end
      end
      unless failed_settings.empty?
        fail "fb_sysctl: Failed setting sysctls: #{failed_settings.join(', ')}"
      end
    end
  end
end
