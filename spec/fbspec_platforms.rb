# frozen_string_literal: true

# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
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

PLATFORMS = if Fauxhai::VERSION.start_with?('6')
              {
                centos7: [
                  {
                    'platform' => 'centos',
                    'version' => '7.3.1611'
                  }
                ],
                mac_os_x: [
                  {
                    'platform' => 'mac_os_x',
                    'version' => '10.12'
                  }
                ]
              }.freeze
            else
              {
                centos8: [
                  {
                    'platform' => 'centos',
                    'version' => '8'
                  }
                ],
                mac_os_x: [
                  {
                    'platform' => 'mac_os_x',
                    'version' => '10.15'
                  }
                ]
              }.freeze
            end
