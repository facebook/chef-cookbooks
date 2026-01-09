#
# Cookbook:: fb_grafana
# Recipe:: default
#
# Copyright (c) 2025-present, Meta Platforms, Inc. and affiliates.
# Copyright (c) 2025-present, Phil Dibowitz
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if defined?(FB::Users)
  FB::Users.initialize_group(node, 'grafana')
  node.default['fb_users']['users']['grafana'] = {
    'action' => :add,
    'home' => '/usr/share/grafana',
    'shell' => '/bin/false',
    'gid' => 'grafana',
  }
end

node.default['fb_apt']['sources']['grafana'] = {
  'key' => 'grafana',
  'url' => 'https://packages.grafana.com/oss/deb',
  'suite' => 'stable',
  'components' => ['main'],
}

# Source: https://apt.grafana.com/gpg-full.key
node.default['fb_apt']['keymap']['grafana'] = <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQGNBGTnhmkBDADUE+SzjRRyitIm1siGxiHlIlnn6KO4C4GfEuV+PNzqxvwYO+1r
mcKlGDU0ugo8ohXruAOC77Kwc4keVGNU89BeHvrYbIftz/yxEneuPsCbGnbDMIyC
k44UOetRtV9/59Gj5YjNqnsZCr+e5D/JfrHUJTTwKLv88A9eHKxskrlZr7Un7j3i
Ef3NChlOh2Zk9Wfk8IhAqMMTferU4iTIhQk+5fanShtXIuzBaxU3lkzFSG7VuAH4
CBLPWitKRMn5oqXUE0FZbRYL/6Qz0Gt6YCJsZbaQ3Am7FCwWCp9+ZHbR9yU+bkK0
Dts4PNx4Wr9CktHIvbypT4Lk2oJEPWjcCJQHqpPQZXbnclXRlK5Ea0NVpaQdGK+v
JS4HGxFFjSkvTKAZYgwOk93qlpFeDML3TuSgWxuw4NIDitvewudnaWzfl9tDIoVS
Bb16nwJ8bMDzovC/RBE14rRKYtMLmBsRzGYHWd0NnX+FitAS9uURHuFxghv9GFPh
eTaXvc4glM94HBUAEQEAAbQmR3JhZmFuYSBMYWJzIDxlbmdpbmVlcmluZ0BncmFm
YW5hLmNvbT6JAdQEEwEKAD4CGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQS1
Oud7rbYwpoMEYAWWP6J3EEWFRQUCaKhvPQUJB4NP1AAKCRCWP6J3EEWFRUjOC/9Y
dWOWJLJVKzLx8uv5YVzebyw15HevhKahbznJX5fHnE8irjkiPFltVEZ4T37s5afR
GBEJnR1UFd80s7jzwbuoZh/zEB3jN8q50g64AznuzDa0PWKzaY7Tgkssx3+hs6TS
vIwV4z8T7f56lDudeHxHXx+htRnZ3ebKNPCJS7+G12GF6W3C3znpdjgvhVUB0uxd
+42V0fRqk2GLNZeKS9988fi5dYRAy9Ozwced7ByCFjde9FBgUtrH3mG1/ibzLEh0
4k02nYjc8mrH32t4UCWpxQEJ1vZA2vT2HN3/cH/4uyFdyU6OHkMyMbz6lmeXe71d
F5hOB4+/RP6Ndyj7ViRNDbm70NRBaFne/+YOJvmMfJTCh7YbF5qEn1ihGkJJ0ohE
u2IB+EGEhyiDm8SIsj1uMw7n17iIPNtbsU5GgnmLtfguP/WbwKV2UeuxTpiOeYb6
blDwRlh48uHMlA5HBW+487Jktw3iPj1IKhdtAC9CU3xAvzDcseMbgmM6Xj2bSQG5
AY0EZOeGaQEMALNIFUricEIwtZiX7vSDjwxobbqPKqzdek8x3ud0CyYlrbGHy0k+
FDEXstjJQQ1s9rjJSu3sv5wyg9GDAUH3nzO976n/ZZvKPti3p2XU2UFx5gYkaaFV
D56yYxqGY0YU5ft6BG+RUz3iEPg3UBUzt0sCIYnG9+CsDqGOnRYIIa46fu2/H9Vu
8JvvSq9xbsK9CfoQDkIcoQOixPuI4P7eHtswCeYR/1LUTWEnYQWsBCf57cEpzR6t
7mlQnzQo9z4i/kp4S0ybDB77wnn+isMADOS+/VpXO+M7Zj5tpfJ6PkKch3SGXdUy
3zht8luFOYpJr2lVzp7n3NwB4zW08RptTzTgFAaW/NH2JjYI+rDvQm4jNs08Dtsp
nm4OQvBA9Df/6qwMEOZ9i10ixqk+55UpQFJ3nf4uKlSUM7bKXXVcD/odq804Y/K4
y3csE059YVIyaPexEvYSYlHE2odJWRg2Q1VehmrOSC8Qps3xpU7dTHXD74ZpaYbr
haViRS5v/lCsiwARAQABiQG8BBgBCgAmAhsMFiEEtTrne622MKaDBGAFlj+idxBF
hUUFAmiobzkFCQeDT9AACgkQlj+idxBFhUVsmQwA0PA/zd7NqtnZ/Z8857gp2Wq2
/e4EX8nRjsW2ZlrZfbU5oMQv9OZZ4z1UjIKEUV+TnCwXEKXTMJomdekQSSayVVx/
u5w+0YM8gRuQGrG8hW0GRR8sHIeuwBFlyQrlwxUwXvDOPDYyieETjaQqMucupIKo
IPm3CjFySvfizvSWUVSWBnGmQfpv6OiGYawvwfewcQHUdLMgWN3lYlzGQJL4+OMm
7XcB8VNTa586Q00fmjDfktHYvGpmhqr3gsd4gS3AjTk0zI65qXBRJkdqVnwUrMUD
8TcxXYNXf90mhR0NWkLmp6kBYiW8+QY6ndMmRVpodg1A87qgMYaZUAAlxCS4XKTU
r+/YMDYOWgLN6i4UeYG/3/hsnAEHm5ITojfh6cLfdlhjohFTnD0IYw3AsNJXRzKB
1g5FTBKLLLIdXgS/3rWV1qjAd3drQVIMCku6HKl/vT4ftrBHeSyV7eLwOYbe3/bw
8VMx+lmMheD8/qJMia1om0iBBRSXRjY//f+Lllqm
=TH3J
-----END PGP PUBLIC KEY BLOCK-----
EOF

# rubocop:disable ChefModernize/ExecuteAptUpdate
execute 'apt-get update' do
  action :nothing
end
# rubocop:enable ChefModernize/ExecuteAptUpdate

package 'grafana-pinned' do
  only_if { node['fb_grafana']['version'] }
  package_name 'grafana'
  version lazy { node['fb_grafana']['version'] }
  action :install
end

package 'grafana-unpinned' do
  not_if { node['fb_grafana']['version'] }
  package_name 'grafana'
  action :upgrade
end

directory '/var/lib/grafana/plugins' do
  owner node.root_user
  group 'grafana'
  mode '0750'
end

execute 'generate self-signed grafana cert' do
  only_if do
    cert_file = node['fb_grafana']['config']['server']['cert_file']
    node['fb_grafana']['gen_selfsigned_cert'] && cert_file &&
      (
        !File.exist?(cert_file) || !File.size?(cert_file)
      )
  end
  command lazy {
    <<~EOF
      key="#{node['fb_grafana']['config']['server']['cert_key']}"
      crt="#{node['fb_grafana']['config']['server']['cert_file']}"
      cn="#{node['fb_grafana']['config']['server']['domain']}"
      openssl req -newkey rsa:4096 -nodes -keyout $key -x509 \
        -subj "/C=US/L=Some City/O=Some Org/CN=$cn" \
        -days 365 -out $crt
    EOF
  }
end

template '/etc/grafana/grafana.ini' do
  owner node.root_user
  group 'grafana'
  mode '0644'
  notifies :restart, 'service[grafana-server]'
end

template '/etc/grafana/provisioning/datasources/datasources.yaml' do
  owner node.root_user
  group 'grafana'
  mode '0644'
  notifies :restart, 'service[grafana-server]'
end

fb_grafana_plugins 'manage' do
  notifies :restart, 'service[grafana-server]'
end

service 'grafana-server' do
  action [:enable, :start]
end
