#
# Cookbook Name:: fb_smartctl
# Recipe:: default
#
# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
#

if node.macos?
  include_recipe 'fb_smartctl::osx'
end
