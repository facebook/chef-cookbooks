fb_users Cookbook
=================
A simple cookbook to provide an attribute-driven API around users and groups
and enforce consistent UIDs and GIDs.

Requirements
------------

Attributes
----------
* node['fb_users']['user_defaults']
* node['fb_users']['user_defaults']['gid']
* node['fb_users']['user_defaults']['manage_home']
* node['fb_users']['user_defaults']['shell']
* node['fb_users']['users']
* node['fb_users']['users'][$USER]
* node['fb_users']['groups']
* node['fb_users']['groups'][$GROUP]
* node['fb_users']['set_passwords_on_windows']

Usage
-----
### Consistent data vs dynamic data

This cookbook draws a hard distinction between information that should not
be changable across an organization and information that should.

Information that should not change like what UID a given user gets when they
are added to a system is stored differently from information that is dynamic
per-system like if the user is on the system and what groups they are a part
of.

### Pre-req: Initializing Consistent data with UID_MAP AND GID_MAP

UIDs, GIDs, and (optionally) user/group system flags or "comments" are
considered consistent data by `fb_users`. These exist in a single map. They do
*not* effect what users or groups are installed on a system and are just a
source of data.

In order to make it this data not modifiable through the run, we put it in
class constants, instead of in the node object. This is not - and should not -
be a common pattern, but it's a clean way of keeping this data (somewhat more)
singley-definable.

In a cookbook of your choice, simply re-open the `FB::Users` class, and define
class constants like so:

```ruby
module FB
  class Users
    UID_MAP = {
      # system
      'root' => {
        'uid' => 0,
        'system' => true,
      },

      # staff...
      'john' => {
        'uid' => 1000,
        'comment' => 'John Smith',
      },
      'sam' => {
        'uid' => 1001,
        'comment' => 'Sam Theman',
      },
      ...

      # service accounts, >= 6k
      'app1' => {
        'uid' => 6000,
      },
      'app2' => {
        'uid' => 6001,
      },
      ...
    }.freeze

    GID_MAP = {
      'root' => {
        'gid' => 0,
        'system' => true,
      }
      'users' => {
        'gid' => 100,
      },
      'docker' => {
        'gid' => 130,
        'comment' => 'Provides access to docker',
      },
      ...
    }
  end
end
```

The default recipe will validate there are no UID or GID conflicts for you,
but you should keep users and groups in order of their UID/GID for your own
sanity.

In addition to providing a integer to specify the `uid`/`gid` for each entity,
you may optionally provide a boolean to specify if it is a `system` user or
group, and provide a `comment`.

All other values must be set in the node object.

### Reserved UID / GID ranges

If you want to protect certain UID / GID ranges from being used across your
managed system, you can add them to `RESERVED_UID_RANGES` and `RESERVED_GID_RANGES`.
This can be useful if 3rd party software creates those users/groups.
The key in the `Hash` will be a printable identifier, the value will be an object
that responds to `.include?()`, so usually `Range` or `Array`.

```ruby
module FB
  class Users
    RESERVED_UID_RANGES = {
      'systemd dynamic users' => 61184..65519,
      'project foo service users' => [52231, 52233],
    }
    RESERVED_GID_RANGES = {
      'project x service groups' => 30100..30200
      'acme corp service groups' => [30100, 30442]
    }
  end
end
```

### Users and Groups

Users and groups are setup using the `users` and `groups` hashes and are
straight forward:

```ruby
node.default['fb_users']['users']['john'] = {
  'shell' => '/bin/zsh',
  'gid' => 'users',
  'action' => :add,
}
node.default['fb_users']['groups']['admins'] = {
  'members' => ['john'],
  'action' => :add,
}
```

`fb_users` will take care to get ordering right to ensure relevant primary
groups exist before creating users that depend on them and all users exist
before group membership is managed.

By design, we do not accept all values. Here are the values we do accept:
* `gid`
* `home`
* `homedir_group`
* `homedir_mode`
* `manage_home`
* `password`
* `shell`
* `secure_token`
* `notifies`

They are all optional, see the next section for how default values for these
work.

The `secure_token` property is used for the `mac_user` resource for Chef 15+

Note that `action` may be `:add` or `:delete`. The default, if not set, is
`:add`, but we highly recommend you be explicit. Doing so will make it really
easy, for example, to set various users to `:delete` early on in your run,
and then if later recipes add them, they'll be added, otherwise they'll be
automatically cleaned up.

Also see `initialize_group` helper below.

The `notifies` is a hash with of notifies, where each notify is a hash with
`resource`, `action`, and `timing`. It looks like this:

```ruby
node.default['fb_users']['users']['zerocool'] = {
  ...
  'notifies' => {
    'restart foo if uid changes' => {
      'resource' => 'service[foo]',
      'action' => 'restart',
      'timing' => 'delayed',
    }
  }
}
```

The name of the notifier is inconsequential, and is only there to make it
easy to reach in and modify a notification later in your run list. The action
can be a string or a symbol, we will do the right thing.

When such a notification is setup, we will run it regardless of if the user or
group is being added, modified, or removed. The only time we don't notify is
if the homedir is being changed.

Note that to enable subscribes, these sub-resources were added to the root
run context, but will be moved back to the subresource run context shortly.

If a user or group can only be determined at runtime or there are recipe
ordering issues, a proc can be given to the `only_if` attribute as a guard.

```ruby
node.default['fb_users']['users']['acidburn'] = {
  'only_if' => proc { node.elite? },
  'action' => :add,
}
```

### Passwords in data_bags

`fb_users` will also look for user passwords in a data_bag called
`fb_users_auth`. The node takes precedent, but if no password is set there,
then data_bags will be checked. This feature is to allow automation of password
generation or syncing.

To use this the item must be named the same as the user, and the element inside
of the item should be `password`. For example,
`data_bags/fb_users_auth/testuser.json` might have the content:

```json
{"id":"testuser","password":<encryptedpassword>}
```

An encrypted password string suitable for passing to the Chef `user` resource
is expected.

If a password is not found in either the node or a data_bag, no password is
set and the user will not be to authenticate via password.

### Defaults for users

Values not specified for users will be handled as follows:

* `gid` - will default to `node['fb_users']['user_defaults']['gid']`
* `home` - will default to `/home/$USER`
* `homedir_group` - will default to the user's GID. This will not be set
   unless `manage_home` is `true`
* `homedir_mode` - will default to the configured system defaults, for example
  `/etc/login.defs`. This will not be set unless `manage_home` is `true`
* `manage_home` - this one is more complex:
   * if `node['fb_users']['user_defaults']['manage_home']` is specified, that
     value will be used
   * otherwise, if the `dirname` of the `home` value appears to be on NFS or
     `autofs`, the value will be set to `false`
   * otherwise the value will be set to `true`
* `shell` - will default to `node['fb_users']['user_defaults']['shell']`

`gid` is required and has no default. It must be set to a group name that appears
in `GID_MAP`.

For all other values we accept, they will only be passed to the resource if
they exist in the user's hash.

### Removing users or groups

To remove a user or group, set the `action` to `:delete` and the user or group
will be automatically cleaned up during the chef run. To automatically clean up
a user's home directory while removing the user from the system, leave
`manage_home` set to `true`.

### Notifications for users or groups

The `user` and `group` resources used within this cookbook's custom resource
will run at the root `run_context` in order to allow other resources in the
chef run to *subscribe* to a specific user or group being updated.

### Windows Support

This cookbook does support Windows, but there are limitations. The greatest
one is that passwords don't really work. We will set them if they are there,
but the `windows_user` resource in Chef requires plain-text passwords, so the
hashed passwords provided for other platforms will set garbage as the password
for Windows. See this bug for details:

https://github.com/chef/chef/issues/10455

In addition, we always ignore UID and GID since the provider crashes on those.
See this bug for details:

https://github.com/chef/chef/issues/10454

This makes sense for local users as Windows does not use UID or GID.

The attribute `set_passwords_on_windows` controls whether or not fb\_users will
even attempt to set passwords for users on Windows, if we have one. It defaults
to `true`, but many users will want to turn this off in a hybrid environment.
As it stands the underlying `windows_user` resource we use can only set
passwords if the plain-text password is passed in, which is suboptimal. So if
you have password-hashes for users for other platforms, you'll likely just want
to set this to `false`. See https://github.com/chef/chef/issues/10455 for more
information.

### Helper methods

This cookbook provides a few helper methods for your convenience:

#### FB::Users.initialize_group(node, groupname)

Since initializing a group nicely involves setting `members` to an empty array
so it may be appended to, we provide a simple method `FB::Users.initialize_group`
which, *if* the group does not exist in the hash *or* was set to delete, will
initialize it as an empty group to add.

#### FB::Users.uid_to_name(uid)

Given a UID for a user in the `UID_MAP` will return the name.

#### FB::Users.gid_to_name(gid)

Given a GID for a group in the `GID_MAP` will return the name.
