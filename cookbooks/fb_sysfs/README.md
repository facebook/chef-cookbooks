fb_sysfs Cookbook
=================
This cookbook provides a resource for managing settings in sysfs

Requirements
------------

Attributes
----------

Usage
-----
This cookbook provides a single resource: `fb_sysfs`, it's usage is:

```ruby
fb_sysfs '/sys/block/sda/queue/scheduler' do
  type :list
  value 'cfq'
end
```

### Types
Not all sysfs files are as simple as the value you write being the value you can
read back out of it. Therefore the `types` tell Chef how to do the idempotency
check:

* `:string` (default) - Compare values as strings, but `chomp` first.
* `:list` - For sysfs files where the output is a list of possible options but
  the 'enabled' one is in brackets. This is common for schedulers. For example,
  on any block device, if you look at the the `scheduler` file for it, you'll
  see something like: `noop deadline [cfq]`. If set to `:list`, then `fb_sysfs`
  will understand this value is `cfq`, and only update it if `value` is
  something else.
* `:int` - Interpret the value is an integer and compare appropriately.

### Value
Value, as you'd expect, is the value to be set. Note that because some `:list`
sysfs files require a newline at the end of `value` to actually take effect,
`fb_sysfs` will always append a newline to `value` if one isn't already
present. Example:

```ruby
# will write "defer\n" to the sysfs file
fb_sysfs '/sys/kernel/mm/transparent_hugepage/defrag' do
  type :list
  value "defer"
end
```

### Path
`path` is the name property, but you may specify it directly should you need to
evaluate it lazily:

```ruby
fb_sysfs "Set some stuff" do
  path lazy { node['fb_foo']['bar'] }
  value 'food'
end
```

### EINVAL handling
Some sysfs paths will return an EINVAL when reads or writes are attempted, to
signal that the underlying driver doesn't support the operation. The resource
provides an `ignore_einval` property, which defaults to false, to control
whether the EINVAL errors should be surfaced or ignored.
