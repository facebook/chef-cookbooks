fb_systemd_reload 'system instance' do
  instance 'system'
  action :nothing
end

fb_systemd_reload 'all user instances' do
  instance 'user'
  action :nothing
end
