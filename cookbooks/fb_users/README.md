fb_users Cookbook
=================
A simple cookbook to provide an attribute-driven API around users and groups
and enforce consistent UIDs and GIDs.

Requirements
------------

Attributes
----------
* node['fb_users']['user_defaults']
* node['fb_users']['user_defaults']['manage_home']
* node['fb_users']['user_defaults']['shell']
* node['fb_users']['user_defaults']['gid']
* node['fb_users']['users']
* node['fb_users']['users'][$USER]
* node['fb_users']['groups']
* node['fb_users']['groups'][$GROUP]

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
UIDs, GIDs, and (optional) user/group "comments" are considered consistent data
by `fb_users`. These exist in a single map. They do *not* effect what users or
groups are installed on a system are are just a source of data.

In order to make it this data not modifiable through the run, we put it in
class constants, instead of in the node object. This is not - and should not -
be a common pattern, but it's a clean way of keeping this data (somewhat more)
singley-definable.

In a cookbook of your choice, simply re-open the `FB::Users` class, and define
class constants like so:

```
module FB
  class Users
    UID_MAP = {
      'root' => {
        'uid' => 0,
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

You may specify a `comment` in addition to `uid`/`gid` for the entity.

All other values must be set in the node object.

### Users and Groups
Users and groups are setup using the `users` and `groups` hashes and are
straight forward:

```
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
* `manage_home`
* `password`
* `shell`

They are all optional, see the next section for how default values for these
work.

Note that `action` may be `:add` or `:delete`. The default, if not set, is
`:add`, but we highly recommend you be explicit. Doing so will make it really
easy, for example, to set various users to `:delete` early on in your run,
and then if later recipes add them, they'll be added, otherwise they'll be
automatically cleaned up.

Also see `initialize_group` helper below.

If you want to protect certain UID / GID ranges from being used across your
managed system, you can add them to `RESERVED_UID_RANGES` and `RESERVED_GID_RANGES`.
This can be useful if 3rd party software creates those users/groups.
The key in the `Hash` will be a printable identifier, the value will be an object
that responds to `.include?()`, so usually `Range` or `Array`.

```
module FB
  class Users
    RESERVED_UID_RANGES = {
      'systemd dynamic users' => 61184..65519,
      'project foo service users' => [52231, 52233],
    }
    RESERVED_GID_RANGES = {
      'project x service groups' => 30100..30200
      'acme corp service groups' => [30100,30442]
    }
  end
end
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

* `home` - will default to `/home/$USER`
* `shell` - will default to `node['fb_users']['user_defaults']['shell']`
* `gid` - will default to `node['fb_users']['user_defaults']['gid']`
* `manage_home` - this one is more complex:
  * if `node['fb_users']['user_defaults']['manage_home']` is specified, that
    value will be used
  * otherwise, if the `dirname` of the `home` value appears to be on NFS or
    `autofs`, the value will be set to `false`
  * otherwise the value will be set to `true`

`gid` is required and has no default. It must be set to a group name that appears
in `GID_MAP`.

For all other values we accept, they will only be passed to the resource if
they exist in the user's hash.

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
