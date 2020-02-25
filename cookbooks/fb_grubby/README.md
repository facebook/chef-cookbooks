fb_grubby Cookbook
==================
A cookbook to manage GRUB configuration via grubby.

Requirements
------------
As a first cut, this currently supports Fedora only.

Attributes
----------
* node['fb_grubby']['manage']
* node['fb_grubby']['kernels']
* node['fb_grubby']['include_args']
* node['fb_grubby']['exclude_args']

Usage
-----
Include `fb_grubby` in your runlist.

Append the arguments you want to make sure are present in the kernel
command-line argument by adding them to `include_args`, and the ones
you want to make sure are absent to `exclude_args`.

`kernels` is pre-populated by all the kernels on the machine; to override
you can use an array of valid paths to any kernel images. For convenience,
`FB::Grubby.default_kernel` will find the path to the current default kernel.

### Example

```
node.default['fb_grubby']['manage'] = true
node.default['fb_grubby']['include_args'] << 'rhgb'
node.default['fb_grubby']['include_args'] << 'quiet'
```
