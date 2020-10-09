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
* node['fb_powershell']['pwsh']['manage']
* node['fb_powershell']['pwsh']['version']

Usage
-----
If you include the cookbook, it won't manage anything by default. You'll need
to set the appropriate attributes depending on your OS.

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
