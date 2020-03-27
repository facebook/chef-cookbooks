action :run do
  settings = node['fb_motd']['update_motd']
  Dir.glob('/etc/update-motd.d/*').each do |motd|
    fname = ::File.basename(motd)
    allow = false
    if settings['enabled']
      if settings['whitelist'].empty?
        # if we're NOT using a whitelist, then the default is allow
        allow = true
      else
        # if we *are* using a whitelist, then we only allow if it's in the
        # list
        allow = settings['whitelist'].include?(fname)
      end
      if !settings['blacklist'].empty? && settings['blacklist'].include?(fname)
        # if we are using a blacklist, and if it's in the blacklist
        # then no matter what, remove it
        allow = false
      end
    else
      allow = false
    end

    file motd do
      owner 'root'
      group 'root'
      mode allow ? '0755' : '0644'
    end
  end
end
