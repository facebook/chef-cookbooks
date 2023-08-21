# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
unified_mode true

resource_name :fb_powershell_module
provides :fb_powershell_module

default_action :upgrade

property :module_name,
         String,
         :required => true,
         :name_property => true
property :version,
         [Integer, String, Array],
         :coerce => proc { |m| Array(m) },
         :default => '0'
property :repository, # rubocop:todo Chef/RedundantCode/PropertyWithRequiredAndDefault
         String,
         :required => true,
         :default => 'PSGallery'
property :skip_publisher_check,
         [true, false],
         :default => false
property :scope,
         String,
         :default => 'AllUsers'

load_current_value do |new_resource|
  # Returns an array
  version powershell_out!(
    <<-EOH,
    $splat = @{
      Name = '#{new_resource.name}'
      ListAvailable = $true
    }
    (Get-Module @splat).Version.ForEach({$_.ToString()})
    EOH
  ).stdout.chomp.split("\r\n").map { |v| Gem::Version.new(v) }
end

action :upgrade do
  Chef::Log.debug("Upgrading module '#{new_resource.module_name}'")

  # Grab all the available modules from the repo once.
  repo_list = get_repo_list

  # Loop over pontential list of versions
  new_resource.version.each do |version|
    # Always convert to <Gem::Version> object!
    new_version = Gem::Version.new(version)
    Chef::Log.debug("Desired version: #{new_version}")

    # Get the latest version in repo
    # Returns <Gem::Version> object
    latest_version = get_latest_version(repo_list, new_version)

    # Get the highest version on disk
    current_version = get_current_version(new_version)

    Chef::Log.debug("Latest version: #{latest_version}")
    Chef::Log.debug("Current version: #{current_version}")
    # See Gem::Version <=> method in ruby docs
    case current_version <=> latest_version
    when -1
      # Higher version
      Chef::Log.debug('Current version is older. Upgrading...')
      install_version = latest_version.to_s
    when 0
      # Same version
      Chef::Log.debug('Versions match. Next...')
      next
    when 1
      # Lower version
      # Upgrade should not try to install older versions.
      Chef::Log.warn(
        "#{new_resource.repository} has #{new_resource.module_name}" +
        " but it is older (#{latest_version}) than what is installed" +
        " (#{current_version}).",
      )
      next
    else # Only alternative is nil
      # Nil is returned if comparison was not with a version.
      fail "The repo does not contain version that matches: #{latest_version}"
    end

    converge_by(
      "upgrade #{new_resource.module_name} from " +
      "#{current_version} to #{install_version}",
    ) do
      splat = {
        'Name' => new_resource.module_name,
        'Repository' => new_resource.repository,
        'Scope' => new_resource.scope,
        'RequiredVersion' => install_version,
        'Force' => true,
        'ErrorAction' => 'Stop',
      }
      if new_resource.skip_publisher_check
        splat['SkipPublisherCheck'] = true
      end

      psscript = <<-EOH
      $splat = @{
      EOH
      splat.each do |k, v|
        psscript += <<-EOH
        #{k} = #{v.eql?(true) ? '$True' : "'#{v}'"}
        EOH
      end
      psscript += <<-EOH
      }
      Install-Module @splat
      EOH
      powershell_out!(psscript)
    end
  end
end

action :install do
  Chef::Log.debug("Installing module '#{new_resource.module_name}'")
  Chef::Log.debug("Current versions: #{current_resource.version.join(', ')}")

  new_resource.version.each do |version|
    install_version = Gem::Version.new(version)
    Chef::Log.debug("Desired version: #{install_version}")

    # if any of the installed versions match, skip it
    if current_resource.version.any?(install_version)
      Chef::Log.debug('Matching version was found. Skipping.')
      next
    end

    converge_by(
      "install #{new_resource.module_name} #{install_version}",
    ) do
      splat = {
        'Name' => new_resource.module_name,
        'Repository' => new_resource.repository,
        'Scope' => new_resource.scope,
        'Force' => true,
        'ErrorAction' => 'Stop',
      }
      unless install_version.to_s.eql?('0')
        splat['RequiredVersion'] = install_version
      end
      if new_resource.skip_publisher_check
        splat['SkipPublisherCheck'] = true
      end

      psscript = <<-EOH
      $splat = @{
      EOH
      splat.each do |k, v|
        psscript += <<-EOH
        #{k} = #{v.eql?(true) ? '$True' : "'#{v}'"}
        EOH
      end
      psscript += <<-EOH
      }
      Install-Module @splat
      EOH

      powershell_out!(psscript)
    end
  end
end

action_class do
  # Returns the latest version from the repo
  # list
  def get_latest_version(
    list,
    version = nil
  )
    Chef::Log.debug(
      "Grabbing the latest version from list: #{list.map(&:to_s).join(', ')}",
    )
    unless version.nil? || version.to_s.eql?('0')
      Chef::Log.debug("Reducing versions to #{version}")
      list = reduce_by_version(list, version)
    end
    latest_version = list.max
    # If Gem::Version.new() is passed an empty string, it returns version 0
    # It is safe to assume there will never be a version 0 and Install-Module
    # will never accept that.
    if latest_version.nil?
      fail "#{new_resource.repository} does not have " +
        "#{new_resource.module_name} with version #{version} " +
        'available to be installed.'
    end
    return latest_version
  end

  # Returns all available version from the repo.
  def get_repo_list
    Chef::Log.debug(
      "Fetching all versions of #{new_resource.module_name} " +
      "from #{new_resource.repository}.",
    )
    latest = powershell_out!(
      <<-EOH,
      $splat = @{
        Name = "#{new_resource.module_name}"
        Repository = "#{new_resource.repository}"
        AllVersions = $True
      }
      (Find-Module @splat).Version.ForEach({$_.ToString()})
      EOH
    ).stdout.to_s.chomp.split("\r\n")
    Chef::Log.debug("Available versions: #{latest.join(', ')}")

    return latest.map { |v| Gem::Version.new(v) }
  end

  # Get the latest version on disk
  # version is Gem::Version object
  def get_current_version(version)
    # 0 would be if we are looking for latest
    if version.to_s.eql?('0')
      Chef::Log.debug(
        'No version filtering. Grabbing the highest version from disk',
      )
      # Current_resource.version is string.
      return Gem::Version.new(current_resource.version.max)
    else
      Chef::Log.debug("Grabbing the highest version of v#{version} from disk.")
      # Grab the highest version that meets the major, minor, build given
      list = current_resource.version.map { |v| Gem::Version.new(v) }
      Chef::Log.debug("Installed versions found: #{list.join(', ')}")

      # Reducing by version can result in nil array.
      max = reduce_by_version(list, version).max
      return max.nil? ? Gem::Version.new(0) : max
    end
  end

  # Limit the list down to the version given
  def reduce_by_version(list, version)
    Chef::Log.debug("Reducing the list down to only v#{version}")
    Chef::Log.debug("List: #{list.join(', ')}")

    # Determine how far we're checking
    seg = version.segments
    count = seg.count

    i = 0
    new_list = list.dup
    until i == count
      new_list.select! { |v| v.segments[i] == seg[i] }
      i += 1
    end
    Chef::Log.debug("New List: #{new_list.join(', ')}")
    return new_list
  end
end
