fb_limits Cookbook
====================
This cookbook allows `/etc/security/limits.conf` to be changed. This controls
limits for PAM sessions (via the `pam_limits` module). Note that on hosts using
systemd, the limits set here will not apply to system services; you should set
any defaults you want using `node['fb_systemd']['system']`.

Requirements
------------

Attributes
----------
* node['fb_limits']

Usage
-----
In limits.conf, each line describes a limit for a user in the form:

    <domain>        <type>  <item>  <value>

Where:
`domain` can be:

* a user name
* a group name, with `@group` syntax
* the wildcard `*`, for default entry
* the wildcard `%`, can be also used with `%group` syntax for `maxlogin` limit

`type` can have one of this two values:

* `soft` for enforcing the soft limits
* `hard` for enforcing hard limits

`item` can be one of the following:

* `core` - limits the core file size (KB)
* `data` - max data size (KB)
* `fsize` - maximum filesize (KB)
* `memlock` - max locked-in-memory address space (KB)
* `nofile` - max number of open files
* `rss` - max resident set size (KB)
* `stack` - max stack size (KB)
* `cpu` - max CPU time (MIN)
* `nproc` - max number of processes
* `as` - address space limit
* `maxlogins` - max number of logins for this user
* `priority` - the priority to run user process with
* `locks` - max number of file locks the user can hold
* `sigpending` - max number of pending signals
* `msgqueue` - max memory used by POSIX message queues (bytes)

Example:

    node.default['fb_limits']['DOMAIN'] = {
        'ITEM' => {
          'TYPE' => VALUE,
          'TYPE' => VALUE,
        }
    }

By default we will assign:

    root nofile soft 65535
    root nofile hard 65535
