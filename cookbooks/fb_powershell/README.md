fb_powershell
==========
This cookbook configures and deploys Powershell for Mac, Linux and Windows.

Requirements
------------
Requires Chocolatey for Windows
Linux requires a repo with Powershell
Mac requires brew access to Powershell

Attributes
----------

* node['fb_powershell']['powershell']['manage']
* node['fb_powershell']['powershell']['version']
* node['fb_powershell']['powershell']['disable_v2']
* node['fb_powershell']['pwsh']['manage']
* node['fb_powershell']['pwsh']['version']
* node['fb_powershell']['pwsh']['version']
* node['fb_powershell']['profiles']['AllUsersAllHosts']
* node['fb_powershell']['profiles']['AllUsersCurrentHost']
* node['fb_powershell']['profiles']['CurrentUserAllHosts']
* node['fb_powershell']['profiles']['CurrentUserCurrentHost']

Usage
-----
If you include the cookbook, it won't manage anything by default. You'll need
to set the appropriate attributes depending on your OS.

### Disable PowerShell v2

This should be the first thing you set. PowerShell v2 is a huge security risk.

```
node.default['fb_powershell']['powershell']['disable_v2'] = true
```

### powershell vs pwsh

Microsoft decided that when it open sourced PowerShell that it would be good to
rebrand the executable. This means that PowerShell Core runs as `pwsh` where as
PowerShell on Windows runs as `powershell`.

Windows PowerShell and PowerShell Core can live side by side but each can only
have one version installed.

### Upgrade Windows Powershell to Latest

```
node.default['fb_powershell']['powershell']['manage'] = true
```

### Upgrade Windows Powershell to Specific Version

```
node.default['fb_powershell']['powershell']['manage'] = true
node.default['fb_powershell']['powershell']['version'] = '5.1.14409'
```

You can see the specific versions available from Chocolatey. If you provide only
a major and minor version it'll will ensure you have a package with at least
that version.

### Install/Upgrade Powershell Core on Windows

```
node.default['fb_powershell']['pwsh']['manage'] = true
```

### Install/Upgrade specific version of Powershell Core on Windows

```
node.default['fb_powershell']['pwsh']['manage'] = true
node.default['fb_powershell']['pwsh']['version'] = '7.0.3'
```

### Upgrade Powershell Core on Linux to Latest

```
node.default['fb_powershell']['pwsh']['manage'] = true
```

### Upgrade Powershell Core on Linux to Specific Version

```
node.default['fb_powershell']['pwsh']['manage'] = true
node.default['fb_powershell']['pwsh']['version'] = '7.0.3'
```

### Install Powershell Core on Mac

```
node.default['fb_powershell']['pwsh']['manage'] = true
```

### Upgrade Powershell Core on Mac to Specific Version

Because the recipe uses the `homebrew_cask` resource, it is only able to install
the cask. You will need to run `brew` commands to upgrade the casks.

See: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7

### Managing profiles
Both versions of PowerShell support 4 types of profiles.

* AllUsersAllHosts
* AllUsersCurrentHost
* CurrentUserAllHosts
* CurrentUserCurrentHost

Typically what is used is "AllUsersAllHosts" which is loaded by every user on a
given machine, and CurrentUserCurrentHost for the current user.

!WARNING: PLEASE NOTE THAT CURRENT USER WILL BE WHATEVER CHEF IS RUNNING AS.

The attributes are nil by default which means the existing files will be left as
is. Once you set the attributes that files will be created/updated to match.

!NOTE: If you are running Windows PowerShell and PowerShell Core both profiles
will be updated.

You can read more about the profile nuances here: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7
