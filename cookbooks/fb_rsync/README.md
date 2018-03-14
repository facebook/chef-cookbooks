fb_rsync Cookbook
====================
Manages rsync, either as a client, or a server.

Requirements
------------

Attributes
----------
* node['fb_rsync']['rsync_command']
* node['fb_rsync']['rsync_server']
* node['fb_rsync']['rsyncd.conf']
* node['fb_rsync']['server']['enabled']
* node['fb_rsync']['server']['start_at_boot']

Usage
-----
The `fb_rsync::client` recipe installs rsync, and sets the
`node['fb_rsync']['rsync_server']` node key. This key contains the rsync
servers that a client can connect to. This is required in `fb_init`, which
means any machine can be an rsync client.

### Being an rsync client
The `fb_rsync` LWRP can be used to run an rsync with configurable options.

    fb_rsync '/usr/facebook/ops/scripts/' do
      source '::ops_scripts/'
      extraopts '--prune-empty-dirs'
      sharddelete true
      sharddeleteexcluded false
      timeout 60
      maxdelete 100
    end

The resulting rsync is configurable but you do not have full control of all
eventual command line options. The default rsync command will run with the
following as required options:
`-avz --timeout --partial --partial-dir=.rsync-partial`
The verbose output is only visible when running chef at the debug log level.

* The destination is set by the resource name (or the destination parameter).
* The source may be a module as shown and the default `rsync_server` will be
used, or you may include the full server name and module. Note that in this
case the LWRP will fail if `rsync_server` is not set.
* The timeout parameter defaults to 60 seconds. A timeout will always be used.
* The extraopts parameter listed above is optional and is additional raw
options to append to the command line for rsync. If you add crazy stuff here
it could be possible to undermine how this LWRP works. If you do this, run chef
with debug and validate that the resulting command line works as you expect.
You should avoid extraopts as much as possible and particularly don't include
options controlled by other paramters such as `--delete`, `--max-deletes`,
`--delete-excluded`.
* `sharddelete` defaults to false. When set to true, it will use the node's
shard to pick 1 hour out of the day during which the rsync will include the
`--delete` and `--max-delete` options. This is to allow for cleanup yet
prevents accidentally mass deleting an important directory (such as if the
source is incorrect). The logs will indicate if deletes were skipped or
applied.
* `maxdelete` is optional and defaults to `100`. This will be the value for the
`--max-delete` option used by sharddelete. Hitting the max will result in a
chef run failure with a custom exception. This is to make mass deletes visible.
You can disable use of `--max-delete` by setting this parameter to `nil`

Note: An `rsync --dry-run` is used when `sharddelete` with `max-delete` will
happen. If the real rsync would fail due to the `max-delete` limit, we refuse
to do the rsync at all and throw an exception. This way, deletes are
all-or-nothing.

* If you are using custom include and exclude options, you may want to use the
`--delete-excluded` option. Sharddelete supports this by additionally adding
the `sharddeleteexcluded` parameter which defaults to `false`. Set it to `true`
along with the `sharddelete` parameter and you'll get `--delete-excluded`
during the hour that sharded deletes happen.

### Deprecated client usage
The LWRP is the preferred way to use rsync, and it uses
`node['fb_rsync']['rsync_server']` to find the rsync server to connect to.  If
the LWRP does not offer the features you need, you may have to build it
yourself.

If you want to mostly use the default rsync options, there is an
`FB::Rsync.cmd` macro that expands to an rsync commandline. If your source path
starts with "::", the `rsync_server` attribute will be added to the front for
you:

    execute 'get_dhcp_configs' do
      command FB::Rsync.cmd("::#{rsync_path}", dhcp_dir)
      action :run
    end

Similar to the LWRP, the macro will fail in this case if `rsync_server` is not
set. If that is not sufficient, you can construct the commandline from scratch
like this:

    execute 'get_dhcp_configs' do
      command "rsync -az #{node['fb_rsync']['rsync_server']}::#{rsync_path}" +
        " #{dhcpd_dir}"
      action :run
    end

### Being an rsync server
The `fb_rsync::server` recipe will install `/etc/init.d/rsyncd`, manage running rsync
in daemon mode, and generate an `/etc/rsyncd.conf`.

If you want to control how the service is managed:
* `node['fb_rsync']['server']['enabled']` defaults to `true` and starts the
service, setting it to `false` will stop the service.
* `node['fb_rsync']['server']['start_at_boot']` defaults to `true` and
enables the service at boot. Setting it to `false` will disable the service at
boot. This means chef will need to run to start the service.

The next step in configuring an rsync server will be setting up the rsync
modules. Modules are defined within
`node['fb_rsync']['rsyncd.conf']['modules']`. All of the module's options will
then be enumerated as part of the module's hash, for example:

    default['fb_rsync']['rsyncd.conf'] = {
      'modules' => {
        'scripts' => {
           'comment' => 'Master file repository for slave hosts',
           'exclude' => '.svn',
           'hosts allow' => 'cc[0-9][0-9].* routablecc[0-9][0-9][0-9].*',
           'list' => 'no',
           'path' => '/usr/local/masterfiles/PROD'
        }
      }
    }

Once you have defined your module you'll need to
add the module name to the `node['fb_rsync']['rsyncd.conf']['enabled_modules']` array. You
can do so by defining the following attribute in your role:

    node.default['fb_rsync']['rsyncd.conf']['enabled_modules'] << 'scripts'

At this point when chef executes the `fb_rsync` recipe `/etc/rsyncd.conf`
will be generated, and the recipe will manage running the rsync service in
daemon mode.
