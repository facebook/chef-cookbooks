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
#

require_relative '../libraries/timers.rb'

describe FB::Systemd::Calendar::Every do
  it 'generates hours' do
    expect(FB::Systemd::Calendar.every(7).hours).to eq('0/7:0:0')
    expect(FB::Systemd::Calendar.every(15).hours).to eq('0/15:0:0')
  end

  it 'generates minutes' do
    expect(FB::Systemd::Calendar.every(7).minutes).to eq('*:0/7:0')
    expect(FB::Systemd::Calendar.every(15).minutes).to eq('*:0/15:0')
  end

  it 'generates weekday' do
    expect(FB::Systemd::Calendar.every.weekday).to eq('Mon..Fri')
  end

  it 'generates week' do
    expect(FB::Systemd::Calendar.every.week).to eq('weekly')
  end

  it 'generates month' do
    expect(FB::Systemd::Calendar.every.month).to eq('monthly')
  end

  it "doesn't generate some things with a value" do
    expect { FB::Systemd::Calendar.every(5).month }.
      to raise_error(RuntimeError)
    expect { FB::Systemd::Calendar.every(5).weekday }.
      to raise_error(RuntimeError)
    expect { FB::Systemd::Calendar.every(5).week }.
      to raise_error(RuntimeError)
  end
end
