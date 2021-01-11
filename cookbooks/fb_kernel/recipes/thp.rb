#
# Cookbook Name:: fb_kernel
# Recipe:: thp
#
# Copyright 2020, Facebook
#
# All rights reserved - Do Not Redistribute
#

# switch THP to background memory defragmentation ...
thp_defrag = '/sys/kernel/mm/transparent_hugepage/defrag'
file thp_defrag do
  not_if { ::File.read(thp_defrag).include?('[defer]') }
  owner 'root'
  group 'root'
  mode '0644'
  content "defer\n"
end
# ... and speed up background THP collapsing by khugepaged
fb_sysfs '/sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs' do
  type :int
  value 1000
end
