fb_chef_hints Cookbook
======================
Apply hints to node attributes from external sources.

Requirements
------------

Attributes
----------

Usage
-----
This cookbook can apply hints provided by external sources onto the node
attribute hierarchy. Depending on your usecase, this can be done at compile or
at runtime.

### Hints at compile time at the end of the runlist
For most usecases, we recommend to include this cookbook at compile time at
the end of the runlist. This can be done by actually adding
`fb_chef_hints::apply_at_compile` at the end of a runlist in a role, or by
including it at the end of a role-specific cookbook. Either way, the result is
that hints will be applied at the end of compile time, only for the affected
role. This means that hints will take precendence over any attribute defaults
and anything else set during compile time beforehand. Hints can still be
overridden however by anything happening later at runtime (e.g. writing in a
`whyrun_safe_ruby_block`).

### Hints at compile time in fb_init
This cookbook can also be included at the _end_ of `fb_init`:

```
include_recipe 'fb_chef_hints::apply_at_compile'
```

Included this way, `fb_chef_hints` will apply hints during compile at the end`
of `fb_init`. Hints will take precendence over any attribute defaults, or
anything set during `fb_init`, but could be overridden by anything happening
later (e.g. tier-specific runs, or recipes writing to the node object at
runtime via a `whyrun_safe_ruby_block`).

### Hints at runtime
This cookbook can also be included at the _beginning_ of `fb_init`:

```
include_recipe 'fb_chef_hints::apply_at_runtime'
```

Included this way, `fb_chef_hints` will apply hints at the beginning of
runtime. Hints will take precendence over any attribute defaults and anything
set during compile time. Hints can still be overridden however by anything
happening later at runtime (e.g. writing in a `whyrun_safe_ruby_block`). Note
that this also means that hints will *not* be visible in `chef-shell -z` when
inspecting the node object.

### Hints format
Hints should be formatted in JSON and dropped under
`/var/chef/attribute_hints`, e.g.

```
$ cat /var/chef/attribute_hints/10_host_agent.json
{
  "source": "host_agent",
  "hint": {
    "fb_sysctl": {
      "kernel.core_uses_pid": 0
    }
  }
}
```

Hints will be processed in lexicographic order, so it's recommended to use
a number prefix in the filename. The JSON should contain two mandatory fields:
- `source`: a string identifying the creator of the override
- `hint`: a hash of the attribute hint itself
Other fields may be added in the future. Fields starting with an underscore
(`_`) are reserved for application usage and will be ignored.

It is expected that each source will drop a single JSON file covering all
hints they require. It is recommented to use the source name in the file, e.g.
`10_host_agent.json` for a source named `host_agent`.

Hints will always overwrite the leaf values they set; specifically:
- if a hint sets an Array, it will overwrite the whole array, not append to it
- if a hint sets a Hash, it will overwrite the whole hash, not merge with it
- if a hint sets something to nil or empty, it will overwrite it

Stale hints can be a source of hard to troubleshoot issues. For this reason, it
is recommended to enforce the removal of hint files older than a certain time.
On systems using systemd, one way do do this can be with `tmpfiles.d`, e.g.:

```
node.default['fb_systemd']['tmpfiles'][hints_glob] = {
  'type' => 'e',
  'age' => '6h',
}
```

One can also request all hints to be removed on boot with:

```
node.default['fb_systemd']['tmpfiles'][hints_glob] = {
  'type' => 'r!',
}
```

### Hints sources
Hints will only be applied if they are attributed to an allowed source. By
default, no hint sources are allowed, and no hints will be applied.

Hint sources are considered consistent data by `fb_chef_hints`. In order to
make this this data not modifiable through the run, we put it in class
constants, instead of in the node object. When deploying `fb_chef_hints`,
create one (and only one) settings cookbook to define these constants.

To define your override sources, re-open the `FB::ChefHintsSiteData` class and
define `ALLOWED_HINTS` as a class constant:

```
module FB
  class ChefHintsSiteData
    ALLOWED_HINTS = [
      'host_agent',
    ]
  end
end
```

### Supported attributes
Hints will only be applied if the relevant attributes have been allowed.
Similar to hints sources (see above), allowed hints are considered consistent
data. To define your allowed attributes, re-open the `FB::ChefHintsSiteData`
class and define `ALLOWED_ATTRIBUTES` as a class constant:

```
module FB
  class ChefHintsSiteData
    ALLOWED_ATTRIBUTES = {
      'fb_sysctl => nil,
      'fb_network_scripts' => {
        'ifup' => {
          'ethtool' => nil,
        },
      },
    }
  end
end
```

In this example, all attributes under `node['fb_sysctl']` will be allowed,
in addition to the `node['fb_network_scripts']['ifup']['ethtool']` attribute.
Note that in the `fb_sysctl` example, this is appropriate because the API for
that cookbook is `node['fb_sysctl'][$KEY][$VAL]`, i.e. it is directly under
the top level key, so we're essentially allowing all sysctl. This is different
from something like `fb_network_scripts`, where the attributes rely on nested
data structures; in this case it is imperative to only allow the most specific
leaf attributes to prevent hard-to-troubleshoot side effects.

Not all attributes are suitable for use in hints. Specifically:
- attributes without a preexisting default are not recommended, unless all
  codepaths consuming them are vetted to ensure sane outcomes when the
  attribute becomes unset
- attributes that are written at runtime (e.g. via a `whyrun_safe_ruby_block`)
  should not be overridden, as precedence cannot be guaranteed in this case
- attributes with disruptive side effects (e.g. ones that might result in a
  service restart, a network bounce or a reboot) are not recommended and
  should be vetted very carefully
- attributes that cannot be safely reverted back to the default value should
  not be used in hints
