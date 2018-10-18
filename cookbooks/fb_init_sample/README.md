fb_init Cookbook
====================
This is a sample - you almost certainly want to fork this and adjust it to
taste. The rest of the Facebook suite of cookbooks are designed to not be
locally modified.

Requirements
------------

Attributes
----------
* node['fb_init']['firstboot_os']
* node['fb_init']['firstboot_tier']

Usage
-----
This cookbook includes all of the opensource Facebook cookbooks. You may not be
ready to use them all, or you may want to include additional stuff, so adjust to
taste.

We've gone ahead and included some extra "HERE: " comments on where we've put
other cookbooks that are internal to give you a better idea of our full
runlist. We hope to be able to release more of these as time allows and where
appropriate.

### Philosophy
It is highly recommended you read through the
[README.md](https://github.com/facebook/chef-cookbooks/blob/master/README.md)
in the root of GitHub repo as well as
[Philosophy.md](https://github.com/facebook/chef-utils/blob/master/Philosophy.md).
The general idea though is that cookbooks are ordered least specific to most
specific. This allows a small core team to make APIs and defaults and then let
individual service owners' cookbooks at the end overwrite whatever they need
to. This also ensures that all things the service owner chooses not to bother
with are setup to sane settings by the core group at your site.

The idea is that your runlists will look include this first, then everything
else. This cookbook should be every "core cookbook" that provides APIs for
everyone else.

It's useful to think of things in a 3-pass system:
  * Setup APIs
    This is what we do in attributes files. Create the structure in the
    node object for people to append to or modify.
  * Use APIs
    In recipes any cookbook can use those APIs by simply writing to the node
    object. The cookbooks in question can set things, but it can all be
    overwritten by "owners" later. This is where the ordering of our model is
    different from other models - we start with the most generic stuff - the
    cookbooks the core OS team writes that should be applicable in general to
    all machines unless someone has a more specific desire. Owners then can
    include other cookbooks that are more specific - maybe for a specific
    cluster, location, type of service. Finally the last cookbooks should be the
    most specific ones for that service or machine which gets the final say.
    Anytime someone removes a node assignment the next-most-specific setting
    will take precdent.
  * Consume APIs
    Everyone who uses any API is generally the cookbook that provides that API,
    so APIs must be consumed only at runtime: templates, ruby_blocks, providers,
    etc.

We have provided an early recipe called `site-settings.rb` in which you can set
the defaults for your organization for all settings Facebook cookbooks provide.
For example, setting all the most reasonable sysctl settings here is advisable
- then let others override them in their later cookbooks. Assuming `fb_init` is
the first thing in your runlist, this is basically the first thing, so any
other cookbooks in your runlist will have time to overwrite them.

### Firstboot
Sometimes it's necessary to distinguish the very first Chef run after
provisioning from subsequent ones, e.g. to do some run-once setup. It's worth
noting this is usually the wrong approach: it is much better to write
idempotent Chef code instead. Alternatively, it can be useful to *prevent*
something from happening during the first run (though again, this should be
last resort).

To do this, the provisioning infrastructure can drop files on disk to tell Chef
it's being run in a specific phase. We choose to split the provisioning process
in two phases:
* an *OS run*, which is the first Chef run after provisioning -- it takes care
  of setting up the basic OS services on the machine, but doesn't do any
  application-specific customization
* a *tier run*, which is the first Chef run after the OS run (i.e. the second
  Chef run after provisioning, assuming the OS run was successful) -- it takes
  care of setting up any application-specific settings and services needed; for
  example, in the case of a webserver this is where we would install and
  configure Apache

On the Chef side, we then provide two attributes to expose the phase:
* `node['fb_init']['firstboot_os']` is true on all runs before the first time
  successful *OS run* happens; this checks for `/root/firstboot_os`
* `node['fb_init']['firstboot_tier']` is true on all runs before the first time
  successful *tier run* happens; this checks for `/root/firstboot_tier`.

These attributes are also wrapped in `fb_helpers` by convenience node methods:
* `node.fistboot_os?` for `node['fb_init']['firstboot_os']`
* `node.firstboot_tier?` for `node['fb_init']['firstboot_tier']`
* `node.firstboot_any_phase?` to encompass both

The reason these are implemented as attributes, and not just node methods, is so
they can be consumed by Chef handlers for reporting purposes.

In `/etc/chef/client.rb`, we also setup a special runlist for the *OS run*:

```ruby
if File.exists?('/root/firstboot_os')
  puts 'INFO: firstboot_os mode, running with limited run_list'
  base = '/etc/chef/run-list-base.json'
  File.write(base, '{"run_list":["role[fb_base]"]}') unless File.exist?(base)
  json_attribs '/etc/chef/run-list-base.json'
else
  json_attribs '/etc/chef/run-list.json'
end
```

Note that for this to work properly, it's important to ensure the flag files
are deleted once the relevant phase has been successfully completed.
