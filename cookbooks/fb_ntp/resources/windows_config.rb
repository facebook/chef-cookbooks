action_class do
  def get_current_config
    config = {}
    section = nil
    s = powershell_exec('w32tm /query /configuration')
    s.result.each do |line|
      case line
      when /^\[(.*)\]$/
        section = $1
        config[section] = {}
      when /^(\w+)\s*:\s*([^\(]+) \(.*\)$/
        config[section][$1] = $2
      end
    end
    config
  end

  def set_ntp_servers
    execute 'set NTP servers' do
      command 'w32tm /configure /reliable:yes /syncfromflags:manual ' +
        "/manualpeerlist:#{node['fb_ntp']['servers'].join(',')} /update"
    end
  end
end

action :config do
  config = get_current_config
  want = node['fb_ntp']['servers']
  have = config['TimeProviders']['NtpServer'].split(',')
  if Set.new(want) != Set.new(have)
    Chef::Log.info(
      'fb_ntp[windows_config]: Changing NTP servers from ' +
      "#{have.join(', ')} to #{want.join(', ')}",
    )
    set_ntp_servers
  else
    Chef::Log.debug('fb_ntp[windows_config]: NTP servers are correct')
  end
end
