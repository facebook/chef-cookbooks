default['fb_sssd'] = {
  'enable' => false,
  'manage_packages' => true,
  'config' => {
    'sssd' => {
      'config_file_version' => 2,
    },
  },
}
