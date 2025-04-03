fb_openport Cookbook
====================
Manage openport

Requirements
------------

Attributes
----------
* node['fb_openport']['manage_packages']
* node['fb_openport']['version']
* node['fb_openport']['download_base_url']
* node['fb_openport']['config']
* node['fb_openport']['config']['options']
* node['fb_openport']['config']['sessions'][$PORT]
* node['fb_openport']['config']['sessions'][$PORT]['options']

Usage
-----

### Packages

By default this cookbook will download and install the openport client package.
You can disable this behavior by setting
`node['fb_openport']['manage_packages']` to `false`.

Since openport is not packaged in (as of this writing) any distributions, this
cookbook uses `remote_file` to download the package appropriate to your
platform from openport directly. If you host a mirror or would otherwise like
this cookbook to get it from some other URL, set
`node['fb_openport']['download_base_url']` to an appropriate URL including any
relevant directories. It will assume the packages are directly in the supplied
directory.

The vversion on `node['fb_openport']['version']` will be downloaded and
installed.

### Configuration

This cookbook uses a parameterized systemd unit file to manage all instances of
openport. This unit file [has been contributed
upstream](https://github.com/openportio/openport-go/pull/4), but is not yet
in any releases.

Unlike the traditional way of managing openport, this means that each instance
you want to start on boot needs to be explicitly enabled, and you can set those
up using the `sessions` hash. Sessons started manually with
`--restart-on-reboot` will *not* be restarted on reboot. This is be design to
follow the FB Cookbook methodology to declare the full desired state in the
cookbook and full manage the service.

Global command-line options can get set in
`node['fb_openport']['config']['options']` which *is an array*. You can append
to it, or remove stuff from it, etc. To override command-line options for a
specific session you can set
`node['fb_openport']['config']['sessions'][$PORT]['options']` to an array.

Here's an example:

```ruby
node.default['fb_openport']['config']['options'] << '-v'
node.default['fb_openport']['config']['sessions']['22'] = {}
node.default['fb_openport']['config']['sessions']['80'] = {
  'options' => '--http-forward',
]
```

The Chef services will be called `service[openport@$PORT]` so you can send
notifies to them. Or you can send a `:restart` notification to
`fb_openport_services[all]` to have this cookbook restart all known services
for you.

Note that this cookbook will cleanup all un-managed openport services and
sysconfig files. So if you were to `systemctl start openport@99`, this cookbook
will notice that and stop and disable it.

### Registration

Currently this cookbook does not handle registration as that requires secret
key handling. How you do that is up to you.
