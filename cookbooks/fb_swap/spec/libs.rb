# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2020-present, Facebook, Inc.
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

def mock_lsblk(rota)
  so = double('lsblk')
  so.should_receive(:run_command).and_return(so)
  so.should_receive(:error!).and_return(nil)
  so.should_receive(:stdout).and_return(
    "{\"blockdevices\": [{\"rota\": \"#{rota}\"}]}",
  )
  Mixlib::ShellOut.should_receive(:new).with(
    'lsblk --json --output ROTA /dev/blocka42',
  ).and_return(so)
end
