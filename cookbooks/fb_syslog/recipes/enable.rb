# this is almost identical to running 'systemctl enable rsyslog', except that it
# has no run-time requirements and can be run while setting up a container.
link '/etc/systemd/system/syslog.service' do
  only_if { node.systemd? }
  to '/usr/lib/systemd/system/rsyslog.service'
  owner 'root'
  group 'root'
end
