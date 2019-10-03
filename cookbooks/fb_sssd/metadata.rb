#
# Copyright (c) 2019-present, Vicarious, Inc.
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

name 'fb_sssd'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
source_url 'https://github.com/facebook/chef-cookbooks/'
description 'Installs/Configures sssd'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
supports 'centos'
supports 'debian'
supports 'ubuntu'
# never EVER change this number, ever.
version '0.1.0'
