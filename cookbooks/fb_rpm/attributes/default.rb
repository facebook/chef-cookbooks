# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2017-present, Facebook, Inc.
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

if (node.fedora? && node['platform_version'].to_i < 33) ||
   (node.centos? && node['platform_version'].to_i < 9)
  db_backend = 'bdb'
else
  db_backend = 'sqlite'
end

default['fb_rpm'] = {
  'macros' => {},
  'manage_packages' => true,
  'rpmbuild' => false,
  'db_backend' => db_backend,
  'allow_db_conversion' => false,
}
