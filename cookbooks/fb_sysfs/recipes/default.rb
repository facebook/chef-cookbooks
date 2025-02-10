template '/etc/sysfs_files_on_boot' do
  source 'sysfs_on_boot.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  variables(:resource_hash=> lazy { node['fb_sysfs']['_set_on_boot'] })
  delayed_action :create
  action :nothing
end

template '/usr/local/bin/set_sysfs_on_boot.py' do
  source 'set_sysfs_on_boot.py.erb'
  owner node.root_user
  group node.root_group
  mode '0755'
  action :create
end

systemd_unit 'set_sysfs_on_boot.service' do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=Run populating sysfs at boot
  After=network.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/set_sysfs_on_boot.py
  TimeoutStartSec=1m
  TimeoutStopSec=2m

  [Install]
  WantedBy=default.target
  EOU
  action [:create, :enable]

end
