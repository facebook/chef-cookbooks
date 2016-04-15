# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
actions :load, :unload
default_action :load

attribute :module_name, :kind_of => String, :name_attribute => true
attribute :verbose, :kind_of => [TrueClass, FalseClass], :default => false
attribute :timeout, :kind_of => Integer, :default => 300
attribute :module_params, :kind_of => [String, Array], :required => false
