#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

moddir = value_for_platform_family(
  # will be a symlink to the right arch dir
  'rhel' => '/etc/httpd/modules',
  'debian' => '/usr/lib/apache2/modules',
)

auth_core_suffix = node.centos6? ? 'default' : 'core'

default['fb_apache'] = {
  'sysconfig' => {
    '_extra_lines' => [],
  },
  'manage_packages' => true,
  'sites' => {},
  'extra_configs' => {},
  'modules' => [
    'alias',
    'auth_basic',
    'auth_digest',
    'authn_file',
    "authn_#{auth_core_suffix}",
    "authz_#{auth_core_suffix}",
    'authz_groupfile',
    'authz_host',
    'authz_user',
    'authz_owner',
    'autoindex',
    'deflate',
    'dir',
    'env',
    'headers',
    'log_config',
    'logio',
    'mime',
    'negotiation',
    'setenvif',
  ],
  'modules_directory' => moddir,
  'modules_mapping' => {
    'actions' => 'mod_actions.so',
    'alias' => 'mod_alias.so',
    'asis' => 'mod_asis.so',
    'auth_basic' => 'mod_auth_basic.so',
    'auth_digest' => 'mod_auth_digest.so',
    'authn_alias' => 'mod_authn_alias.so',
    'authn_anon' => 'mod_authn_anon.so',
    'authn_dbd' => 'mod_authn_dbd.so',
    'authn_dbm' => 'mod_authn_dbm.so',
    'authn_core' => 'mod_authn_core.so',
    'authn_file' => 'mod_authn_file.so',
    'authnz_ldap' => 'mod_authnz_ldap.so',
    'authz_dbm' => 'mod_authz_dbm.so',
    'authz_core' => 'mod_authz_core.so',
    'authz_groupfile' => 'mod_authz_groupfile.so',
    'authz_host' => 'mod_authz_host.so',
    'authz_owner' => 'mod_authz_owner.so',
    'authz_user' => 'mod_authz_user.so',
    'autoindex' => 'mod_autoindex.so',
    'cache' => 'mod_cache.so',
    'cern_meta' => 'mod_cern_meta.so',
    'cgid' => 'mod_cgid.so',
    'cgi' => 'mod_cgi.so',
    'dav_fs' => 'mod_dav_fs.so',
    'dav' => 'mod_dav.so',
    'dbd' => 'mod_dbd.so',
    'deflate' => 'mod_deflate.so',
    'dir' => 'mod_dir.so',
    'disk_cache' => 'mod_disk_cache.so',
    'dumpio' => 'mod_dumpio.so',
    'env' => 'mod_env.so',
    'expires' => 'mod_expires.so',
    'ext_filter' => 'mod_ext_filter.so',
    'filter' => 'mod_filter.so',
    'headers' => 'mod_headers.so',
    'ident' => 'mod_ident.so',
    'include' => 'mod_include.so',
    'info' => 'mod_info.so',
    'ldap' => 'mod_ldap.so',
    'log_config' => 'mod_log_config.so',
    'log_forensic' => 'mod_log_forensic.so',
    'logio' => 'mod_logio.so',
    'mime' => 'mod_mime.so',
    'mime_magic' => 'mod_mime_magic.so',
    'negotiation' => 'mod_negotiation.so',
    'php5' => 'libphp5.so',
    'proxy_ajp' => 'mod_proxy_ajp.so',
    'proxy_balancer' => 'mod_proxy_balancer.so',
    'proxy_connect' => 'mod_proxy_connect.so',
    'proxy_ftp' => 'mod_proxy_ftp.so',
    'proxy_http' => 'mod_proxy_http.so',
    'proxy' => 'mod_proxy.so',
    'proxy_scgi' => 'mod_proxy_scgi.so',
    'reqtimeout' => 'mod_reqtimeout.so',
    'rewrite' => 'mod_rewrite.so',
    'setenvif' => 'mod_setenvif.so',
    'speling' => 'mod_speling.so',
    'ssl' => 'mod_ssl.so',
    'status' => 'mod_status.so',
    'substitute' => 'mod_substitute.so',
    'suexec' => 'mod_suexec.so',
    'unique_id' => 'mod_unique_id.so',
    'userdir' => 'mod_userdir.so',
    'usertrack' => 'mod_usertrack.so',
    'version' => 'mod_version.so',
    'vhost_alias' => 'mod_vhost_alias.so',
    'wsgi' => 'mod_wsgi.so',
  },
  'module_packages' => {
    'wsgi' => value_for_platform_family(
      'rhel' => 'mod_wsgi',
    ),
    'php5' => value_for_platform_family(
      'rhel' => 'mod_php',
    ),
    'ssl' => value_for_platform_family(
      'rhel' => 'mod_ssl',
    ),
  },
}

if node.centos?
  {
    'options' => [],
    'lang' => 'C',
  }.each do |k, v|
    node.default['fb_apache']['sysconfig'][k] = v
  end
elsif node.debian?
  {
    'htcacheclean_run' => 'auto',
    'htcacheclean_mode' => 'daeon',
    'htcacheclean_size' => '300M',
    'htcacheclean_daemon_interval' => '120',
    'htcacheclean_path' => '/var/cache/apache2/mod_cache_disk',
    'htcacheclean_options' => ['-n'],
  }.each do |k, v|
    node.default['fb_apache']['sysconfig'][k] = v
  end
end
