class Chef
  # Our extensions of the node object
  class Node
    def centos?
      return self['platform'] == 'centos'
    end

    def centos7?
      return self.centos? && self['platform_version'].start_with?('7')
    end

    def centos6?
      return self.centos? && self['platform_version'].start_with?('6')
    end

    def centos5?
      return self.centos? && self['platform_version'].start_with?('5')
    end

    def ubuntu?
      return self['platform'] == 'ubuntu'
    end

    def linux?
      return self['os'] == 'linux'
    end

    def macosx?
      return self['platform'] == 'mac_os_x'
    end

    def yocto?
      return self['platform_family'] == 'yocto'
    end

    def systemd?
      return self.centos7?
    end

    def virtual?
      return self['virtualization'] &&
        self['virtualization']['role'] == 'guest'
    end

    def container?
      if ENV['container'] && ENV['container_uuid']
        return true
      else
        return false
      end
    end
  end
end
