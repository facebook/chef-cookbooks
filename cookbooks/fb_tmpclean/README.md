fb_tmpclean Cookbook
====================
This cookbook allows you to customize how you would like directories cleaned
to ensure more appropriate filesystem cleanup.

Requirements
------------
Supports five platforms:
* CentOS  = tmpwatch
* Debian  = tmpreaper
* Fedora  = tmpwatch
* macOS   = tmpreaper
* Windows = powershell script

Attributes
----------
* node['fb_tmpclean']['default_files']
* node['fb_tmpclean']['directories']
* node['fb_tmpclean']['excludes']
* node['fb_tmpclean']['timestamptype']
* node['fb_tmpclean']['extra_lines']
* node[;fb_tmpclean']['windows_script_location']

Usage
-----
### READ THIS: Warnings

First, for Linux systems, we highly recommend you use the systemd-tmpfiles
mechanism exposed through `fb_systemd` in a clean way. This cookbook was
originally written with specific design constraints that attempted to provide a
single API to 3 different temp file cleaning tools that are quiet different,
and as a result, are quite awkward with all 3.

Second, in order to support different times for different files and
directories, this cookbook overwrites the cron script included with
tmpclean/tmpreaper to call the relevant comamnd several times for each
different directory. This means that the standard config variables used in, for
example, `/etc/tmpreaper.conf` aren't used, so using this cookbook means using
these packages a bit differently than you might be used to.

### Overview

This cookbook allows you to easily add/change directory cleanup rules and
provide per-directory settings, easily. By default, tmpclean takes time in
hours, or you may suffix with `m` (minutes), `h` (hours), or `d` (days).

The attributes are used like this:

### default_files

This is the lifetime of the files that are cleaned up by default by
the respective packages. It defaults to 240, and the files covered are:

* CentOS and Fedora Includes (if exists)
  `/var/{cache/man,catman}/{cat?,X11R6/cat?,local/cat?}`

* Windows includes (if exists)
  `c:\\windows\\temp,c:\\temp`

### directories

This is a hash of directories you'd like cleaned and the lifetime of files.

Add other entries as you need.

### excludes

This is an array of files to exclude from cleaning in all directories listed in
`node['fb_tmpclean']['directories']`.

Both tmpwatch (CentOS, Fedora) and tmpreaper (Debian, macOS) use shell patterns
for `excludes`. However, these "shell patterns" differ subtly on the two
platforms, so test carefully. The defaults for `excludes` change per platform.

When the cron job is built, each of the excludes is appended to the list of
directories with a slash appended to the directory name. An exclusion of
`/tmp/file` with a directory of `/tmp` will result in a `-X` of
`/tmp//tmp/file`. The way the options are constructed, each exclusion is
appended to each directory to create absolute paths.

```
for dir in directories:
    for exclusion in exclusions:
        print '-X ' + dir + '/' + exclusions
```

Windows uses the -exclude parameter to Get-Childitem, which also takes globs, however
the globs are file globs in this case

### timestamptype

By default we tell tmpwatch (on CentOS and Fedora) and tmpreaper (on Debian and
macOS) to use mtime, but you can change this by setting
`node['fb_tmpclean']['timestamptype']` to `atime`.

To ensure that empty directories get removed, we still force tmpreaper to use
mtime on directories even when using atime for files, since directories' atime
get updated when their contents get tested.

#### timestamptype per directory (RHEL-based systems only)

On Linux the risk of trusting on `node['fb_tmpclean']['timestamptype']` is at
the cost of impacting other cookbooks. If during your chef run multiple
cookbooks setup the value it will impact others, the last to set value in the
order will be the final config. Meaning if you set `atime` but someones changes
to `mtime` your cookbook might not run as expected.

This previous constraint raises the issue where impacting dependencies. A good
practice to follow is to set the timestamptype per directory level, meaning you
only modify yours.

To set the timestamp type for specific directory follow next example:
`node['fb_tmpclean']['directories']['/the/directory']['timestamptype'] = 'mtime'`
`node['fb_tmpclean']['directories']['/the/directory']['interval'] = '3d'`

This is supported only on tmpclean-based systems (RHEL family).

### extra_lines

An array of extra lines that will be put, verbatim, into the config file.

Examples:

```
node.default['fb_tmpclean']['directories']['/home/zuck'] = 1
node.default['fb_tmpclean']['extra_lines'] << "LINE"
```

### remove_special_files

A boolean value which determines whether or not tmpwatch will remove special
filetypes.

Defaults:

* `default_files` = 240 hours
* excludes are set per-platform based on the tool's defaults. See
  `attributes/default.rb'
* `remove_special_files` defaults to false to avoid a default case that may be
  dangerous

### windows_script_location

This is where the windows powershell script is generated - it will be called as a
schedulded task based on the timings specified in the other node attributes.  It
defaults to c:\chef\fbit\cleanup-tmp.ps1.
