require 'fileutils'

property :httpdir, String
property :moddir, String
property :sitesdir, String
property :confdir, String

default_action :verify

action :verify do
  # Verify configurations of interest using apache syntax checker `httpd -t`.
  # By default, this command run ondisc files which is too late for Chef to
  # catch anything invalid. To catch bad configs ahead of time, we copy the
  # existing configurations to a temp directory and materialize the new
  # configurations in the same and then run validator on it. This way,
  # validation happens on new configurations without touching the live ones.
  ::Dir.mktmpdir do |tdir|
    Chef::Log.
      debug("fb_apache: copy from '#{new_resource.httpdir}' to '#{tdir}'")
    FileUtils.cp_r("#{new_resource.httpdir}/.", tdir)

    # This is some trickery. We change the "ServerRoot" to the temp
    # folder we created.
    #
    # Context - `httpd.conf` is the main config that loads other modules and
    # configs. `httpd.conf` lives in the canonical location called "server
    # root". `httpd` cli allows one to change server root using `-d` option,
    # however that only changes the location of where it finds `httd.conf`; it
    # does not change the paths from which "other" configs are loaded. To really
    # change the paths where other configs are loaded we have to change the
    # "ServerRoot" in `httpd.conf` from the canonical `/etc/httpd` to
    # `/tmp/<whatever>`. This way, all the other configurations in the temp
    # folder are correctly loaded and verified.
    Chef::Log.debug("fb_apache: modify contents of '#{tdir}/conf/httpd.conf'")
    file = Chef::Util::FileEdit.new("#{tdir}/conf/httpd.conf")
    file.search_file_replace_line(%r{^ServerRoot "/etc/httpd"$},
                                  "ServerRoot \"#{tdir}\"") ||
      fail('Apache validation failed. Cannot find `ServerRoot /etc/httpd`')
    file.write_file

    # we manually build the resource so that Chef does not add these to its
    # resource collection and hence not track it for "updates".
    build_resource(:template,
                   "#{tdir}/#{new_resource.moddir}/fb_modules.conf") do
      not_if { node.centos6? }
      owner 'root'
      group 'root'
      mode '0644'
      source 'fb_modules.conf.erb'
    end.run_action(:create)

    build_resource(:template,
                   "#{tdir}/#{new_resource.sitesdir}/fb_sites.conf") do
      owner 'root'
      group 'root'
      mode '0644'
      source 'fb_sites.conf.erb'
    end.run_action(:create)

    build_resource(:template,
                   "#{tdir}/#{new_resource.confdir}/fb_apache.conf") do
      owner 'root'
      group 'root'
      mode '0644'
      source 'fb_apache.conf.erb'
    end.run_action(:create)

    build_resource(:template,
                   "#{tdir}/#{new_resource.moddir}/00-mpm.conf") do
      source '00-mpm.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
    end.run_action(:create)

    build_resource(:template,
                   "#{tdir}/#{new_resource.confdir}/status.conf") do
      source 'status.erb'
      owner 'root'
      group 'root'
      mode '0644'
      variables(:location => '/server-status')
    end.run_action(:create)

    verify_cmd = value_for_platform_family(
      'rhel' => "httpd -t -d #{tdir}",
      'debian' => "apachectl -t -d #{tdir}",
    )
    Chef::Log.debug("fb_apache: verify using #{verify_cmd}")
    s = shell_out(verify_cmd)
    s.error!
  end
end
