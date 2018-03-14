fb_ipc Cookbook
===============
Controls shared memory segments on a server

Requirements
------------

Attributes
----------

Usage
-----
Add `fb_ipc` to `metadata.rb` for your cookbook, and then use the
`fb_ipc` resource to delete a given shared memory segment:

```
fb_ipc 42 do
  action :remove
  type :shm
end
```
