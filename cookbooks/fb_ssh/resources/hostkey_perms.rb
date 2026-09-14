action :run do
  Dir.glob(::File.join(FB::SSH.confdir(node), '*key')).each do |f|
    file f do
      if node.windows?
        rights :full_control, 'Administrators'
        rights :full_control, 'SYSTEM'
        inherits false
      else
        owner 'root'
        group node.root_group
        mode '0600'
      end
    end
  end
end
