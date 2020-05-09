property :mod_dir, String

action :manage do
  allowed = [
    "#{new_resource.mod_dir}/00-mpm.conf",
    "#{new_resource.mod_dir}/fb_modules.conf",
  ]
  Dir.glob("#{new_resource.mod_dir}/*").each do |f|
    next if allowed.include?(f)
    if ::File.symlink?(f)
      link f do
        action :delete
      end
    else
      file f do
        action :delete
      end
    end
  end
end
