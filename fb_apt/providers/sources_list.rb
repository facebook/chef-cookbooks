# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

def whyrun_supported?
  true
end

use_inline_resources

action :run do
  repos = []
  mirror = node['fb_apt']['mirror']
  distro = node['lsb']['codename']

  # only add base repos if mirror is set and codename is available
  if mirror && distro
    components = 'main'
    if node.ubuntu?
      components += ' universe'
    end

    if node['fb_apt']['want_non_free']
      if node.debian?
        components += ' contrib non-free'
      elsif node.ubuntu?
        components += ' restricted multiverse'
      else
        fail "Don't know how to setup non-free for #{node['platform']}"
      end
    end

    base_repos = [
      # Main repo
      "#{mirror} #{distro} #{components}",
    ]

    # Security updates
    if node.debian?
      base_repos <<
        "http://security.debian.org/ #{distro}/updates #{components}"
    elsif node.ubuntu?
      base_repos <<
        "http://security.ubuntu.com/ #{distro}-security #{components}"
    end

    # Stable updates
    base_repos << "#{mirror} #{distro}-updates #{components}"

    if node['fb_apt']['want_backports']
      base_repos << "#{mirror} #{distro}-backports #{components}"
    end

    base_repos.each do |repo|
      repos << "deb #{repo}"
      if node['fb_apt']['want_source']
        repos << "deb-src #{repo}"
      end
    end
  end

  # add custom repos
  repos += node['fb_apt']['repos']

  template '/etc/apt/sources.list' do
    source 'sources.list.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(:repos => repos)
  end
end
