include_recipe 'fb_apache'
if node.debian? || (node.ubuntu? && !node.ubuntu16?)
  include_recipe 'fb_apt_cacher'
end

# Currently fb_reprepro is broken
# https://github.com/facebook/chef-cookbooks/issues/78
# include_recipe 'fb_reprepro'

# Currently fb_zfs is broken
# https://github.com/facebook/chef-cookbooks/issues/79
# include_recipe 'fb_zfs'
