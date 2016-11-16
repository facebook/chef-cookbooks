# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#
actions :load, :unload
default_action :load

attribute :module_name, :kind_of => String, :name_attribute => true
attribute :verbose, :kind_of => [TrueClass, FalseClass], :default => false
attribute :timeout, :kind_of => Integer, :default => 300
attribute :fallback, :kind_of => [TrueClass, FalseClass], :default => false
attribute :module_params, :kind_of => [String, Array], :required => false
