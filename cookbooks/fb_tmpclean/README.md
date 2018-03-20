fb_tmpclean Cookbook
====================
This cookbook allows you to customize how you would like directories cleaned
to ensure more appropriate filesystem cleanup.

Requirements
------------
Supports three platforms:
* CentOS = tmpwatch
* Debian = tmpreaper
* macOS  = tmpreaper

Attributes
----------
* node['fb_tmpclean']['default_files']
* node['fb_tmpclean']['directories']
* node['fb_tmpclean']['excludes']
* node['fb_tmpclean']['timestamptype']
* node['fb_tmpclean']['extra_lines']

Usage
-----
Anywhere, in any cookbook, you can set tmpclean to be tuned to the needs of a
tier or server. By default, tmpclean takes time in hours, or you may suffix
with `m` (minutes), `h` (hours), or `d` (days).

The attributes are used like this:

### default_files

This is the lifetime of the files that are cleaned up by default by
the respective packages. It defaults to 240, and the files covered are:

* CentOS Includes (if exists)
  `/var/{cache/man,catman}/{cat?,X11R6/cat?,local/cat?}`

### directories

This is a hash of directories you'd like cleaned and the lifetime of files.

Add other entries as you need.

### excludes

This is an array of files to exclude from cleaning in all directories listed in
`node['fb_tmpclean']['directories']`.

Both tmpwatch (CentOS) and tmpreaper (Debian, macOS) use shell patterns for
`excludes`. However, these "shell patterns" differ subtly on the two platforms,
so test carefully. The defaults for `excludes` change per platform.

When the cron job is built, each of the excludes is appended to the list of
directories with a slash appended to the directory name. An exclusion of
`/tmp/file` with a directory of `/tmp` will result in a `-X` of
`/tmp//tmp/file`. The way the options are constructed, each exclusion is
appended to each directory to create absolute paths.

    for dir in directories:
        for exclusion in exclusions:
            print '-X ' + dir + '/' + exclusions

### timestamptype

By default we tell tmpwatch (on CentOS) and tmpreaper (on Debian and macOS) to
use mtime, but you can change this by setting
`node['fb_tmpclean']['timestamptype']` to `atime`.

To ensure that empty directories get removed, we still force tmpreaper to use
mtime on directories even when using atime for files, since directories' atime
get updated when their contents get tested.

### extra_lines

An array of extra lines that will be put, verbatim, into the config file.

Examples:

    node.default['fb_tmpclean']['directories']['/home/zuck'] = 1
    node.default['fb_tmpclean']['extra_lines'] << "LINE"

### remove_special_files

A boolean value which determines whether or not tmpwatch will remove special
filetypes.

Defaults:

* `default_files` = 240 hours
* excludes are set per-platform based on the tool's defaults. See
  `attributes/default.rb'
* `remove_special_files` defaults to false to avoid a default case that may be
  dangerous
