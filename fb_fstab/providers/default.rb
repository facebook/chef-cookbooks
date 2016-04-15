# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

require 'fileutils'

include FB::FstabProvider

def whyrun_supported?
  true
end

action :doeverything do
  # Unmount filesystems we don't want
  check_unwanted_filesystems
  # Mount or update filesystems we want
  check_wanted_filesystems
end
