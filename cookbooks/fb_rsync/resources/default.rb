# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2012-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

actions :sync
default_action :sync
attribute :destination, :kind_of => String, :name_attribute => true,
                        :required => true
attribute :source, :kind_of => String, :required => true
attribute :sharddelete, :kind_of => [TrueClass, FalseClass], :default => false
attribute :sharddeleteexcluded, :kind_of => [TrueClass, FalseClass],
                                :default => false
attribute :extraopts, :kind_of => String, :default => ''
attribute :partial, :kind_of => [TrueClass, FalseClass], :default => true
attribute :timeout, :kind_of => Integer, :default => 60
attribute :maxdelete, :kind_of => Integer, :default => 100
