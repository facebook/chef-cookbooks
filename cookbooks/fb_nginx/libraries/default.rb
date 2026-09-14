module FB
  class Nginx
    def self.module_dir
      if ::ChefUtils.fedora_derived?
        '/etc/nginx/conf.modules.d'
      elsif ::ChefUtils.debian?
        '/etc/nginx/modules-enabled'
      else
        fail 'fb_nginx: unknown platform_family'
      end
    end

    def self.user
      if ::ChefUtils.fedora_derived?
        'apache'
      elsif ::ChefUtils.debian?
        'www-data'
      else
        fail 'fb_nginx: unknown platform_family'
      end
    end
  end
end
