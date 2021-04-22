fb_iproute Cookbook
=================
This cookbook manages iproute.

Requirements
------------
CentOS

Attributes
----------
* node['fb_iproute']['manage_packages']

Usage
-----
Just include the cookbook in your runlist. If you'd like to manage the iproute
packages yourself, set `node['fb_iproute']['manage_packages']` to false.

Protocol Support
----------------

This cookbook can also add protocol ID mappings to `/etc/iproute2/rt_protos.d/`.

To add a protocol, simply add to the 'rt_proto_ids' hash in this recipes attributes.

Example:

```ruby
node.default['fb_iproute']['rt_protos_ids'] = {
  'cooper' => 69,
}
```
