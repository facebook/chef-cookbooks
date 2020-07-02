# Facebook Cookbooks Suite

![Continuous Integration](https://github.com/facebook/chef-cookbooks/workflows/Continuous%20Integration/badge.svg?event=push)

This repo contains attribute-driven-API cookbooks maintained by Facebook. It's
a large chunk of what we refer to as our "core cookbooks."

It's worth reading our
[Philosophy.md](https://github.com/facebook/chef-utils/blob/master/Philosophy.md)
doc before reading this. It covers how we use Chef and is important context
before reading this.

It is important to note that these cookbooks are built using a very specific
model that's very different from most other cookbooks in the community.
Specifically:

* It assumes an environment in which you want to delegate. The cookbooks are
  designed to be organized in a "least specific to most specific" order in the
  runlist. The runlist starts with the "core cookbooks" that setup APIs and
  enforce a base standard, which can be adjusted by the service owners using
  cookbooks later in the runlist.
* It assumes a "run from master" type environment. At Facebook we use [Grocery
  Delivery](http://www.github.com/facebook/grocery-delivery) to sync the master
  branch of our git repo with all of our Chef servers. Grocery Delivery is not
  necessary to use these cookbooks, but since they were built with this model in
  mind, the versions never change (relatedly: we do not use environments).
* It assumes you have a testing toolset that allows anyone modifying later
  cookbooks to ensure that their use of the API worked as expected on a live
  node before committing. For this, we use [Taste
  Tester](http://www.github.com/facebook/taste-tester).

Cookbooks in this repo all being with `fb_` to denote that not only do they
use the Facebook Cookbook Model, but that they are maintained in this repo.

Local cookbooks or cookbooks in other repositories that implement this model
should not use this prefix, but should reference this document in their docs.


## APIs

Unlike other cookbook models, we do not use resources as APIs, we use the node
object. Configuration is modeled in arrays and hashes as closely and thinly as
possible to the service we are configuring. Ideally, you should only have to
read the docs to the service to configure it, not the docs to the cookbook.
 
For example, if the service we are configuring has a key-value pair
configuration file, we will provide a simple hash where keys and values will be
directly put into the necessary configuration file.

There are two reasons we use attribute-driven APIs:

1. Cascading configuration
   Since our cookbooks are ordered least specific (core team that owns Chef) to
   most specific (the team that owns this machine or service) it means that the
   team who cares about this specific instance can always override anything. This
   enables stacking that is not possible in many other models. For example, you
   can have a runlist that looks like:

   * Core cookbooks (the ones in this repo)
   * Site/Company cookbooks (site-specific settings)
   * Region cookbooks (overrides for a given region/cluster)
   * Application Category cookbooks (webserver, mail server, etc.)
   * Specific Application cookbook ("internal app1 server")

   So let's say that you want a specific amount of shared memory by default,
   but in some region you know you have different size machines, so you shrink
   it, but web servers need a further different setting, and then finally some
   specific internal webserver needs an even more specific setting... this all
   just works.

   Further, a cookbook can see the value that was set before it modifies things,
   so the 'webserver' cookbook could look to see what the value was (small or
   large) before modifying it and adjust it accordingly (so it could be relative
   to the size of memory that the 'region' cookbook set.

   Using resources for this does not allow this "cascading", it instead
   creates "fighting". If you use the cron resource to setup an hourly job,
   and then someone else creates a cron for that same job but only twice
   a day, then during each Chef run the cron job gets modified to hourly, then
   re-modified to twice a day.

2. Allows for what we refer to as "idempotent systems" instead of "idempotent
   settings." In other words, if you only manage a specific item in a larger
   config, and then you stop managing it, it should either revert to a
   less-specific setting (see #1) or be removed, as necessary.

   For example let's say you want to set a cron job. If you use the internal
   cron resource, and then delete the recipe code that adds that cronjob, that
   cron isn't removed from your production environment - it's on all existing
   nodes, but not on any new nodes.

   For this reason we use templates to take over a whole configuration wherever
   possible. All cron jobs in our `fb_cron` API are written to
   `/etc/cron.d/fb_crontab`. If you delete the lines adding a cronjob, since
   they are just entries in a hash, when the template is generated on the next
   Chef run, those crons go away.

   Alternatively, consider a sysctl set by the "site" cookbook, then overwritten
   by a later cookbook. When that later code is removed, the entry in the hash
   falls back to being set again by the next-most-specific value (i.e. the "site" 
   cookbook in this case).
 

## Runlists

How you formulate your runlists is up to your site, as long as you follow the
basic rule that core cookbooks come first and you order least-specific to
most-specific. At Facebook, all of our runlists are:

    recipe[fb_init], recipe[$SERVICE]

Where `fb_init` is similar to the sample provided in this repo, but with extra
"core cookbooks."

We generally think of this way: `fb_init` should make you a "Facebook server" 
and the rest should make you a whatever-kind-of-server-you-are.


## Getting started

Grab a copy of the repo, rename `fb_init_sample` to `fb_init`, and follow the
instructions in its 
[README.md](https://github.com/facebook/chef-cookbooks/blob/master/cookbooks/fb_init_sample/README.md)
(coordinating guidance is in comments in the
default recipe).


## Other Guidelines

### Modules and classes in cookbooks

It is often useful to factor out logic into a library - especially logic that
doesn't create resources. Doing so makes this logic easier to unit test and
makes the recipe or resource cleaner.

Our standard is that all cookbooks use the top-level container of `module FB`,
and then create a class for their cookbook under that. For example, `fb_fstab`
creates a `class Fstab` inside of the `module FB`. We will refer to this as
the cookbook class from here.

We require all cookbooks use this model for consistency.

Since we don't put anything other than other classes inside the top-level
object, it's clear that a `module` is the right choice.

While there is no reason that a cookbook class can't be one designed to be
instantiated, more often than not it is simply a collection of class methods and
constants (i.e. static data and methods that can then be called both from this
cookbook and others).

Below the cookbook class, the author is free to make whatever class or methods
they desire.

When building a complicated Custom Resource, the recommended pattern is to
factor out the majority of the logic into a module, inside of the cookbook
class, that can be `include`d in the `action_class`. This allows the logic to be
easily unit tested using simple rspec. It is preferred for this module to be in
its own library file, and for its name to end in `Provider`, ala
`FB::Thing::ThingProvider`.

When more than 1 or 2 methods from this module are called from the custom
resource itself, it is highly recommended you include it in a Helper class for
clarity, ala:

```
action_class do
  class ThingHelper
    include FB::Thing::ThingProvider
  end
end
```

In this way, it is clear where methods come from.

### Extending the node vs self-contained classes

You may have noticed that some of our cookbooks will extend the `node` object,
while others have self-contained classes that sometimes require the `node` be
passed as a parameter to some methods.

In general, the **only** time when extending the `node` is acceptable is when
you are simply making a convenience function around using the node object. So,
for example, instead of making people do `node['platform_family'] = 'debian'`,
there's a `node.debian?`. This is simply syntactic sugar on top of data entirely
in the node.

In all other cases, one should simply have the `node` be an arguement passed on,
so as to not pollute the node namespace. For example, a method that looks at the
node attributes, but also does a variety of other logic, should be in a cookbook
class and take the node as an argument (per standard programming paradigms about
clear dependencies).

### Methods in recipes

Sometimes it is convenient to put a method directly in a recipe. It is strongly
preferred to put these methods in the cookbook class, however there are some
cases where methods directly in recipes make sense. The primary example is a
small method which creates a resource based on some input to make a set of loops
more readable.

### Methods in templates

Methods should not be put into templates. In general, as little logic as
possible should be in templates. In general the easiest way to do this is to put
the complex logic into methods in your cookbook class and call them from the
templates.

### Err on the side of fail

Chef is an ordered system and thus is designed to fail a run if a resource
cannot be converged. The reason for this is that if one step in an ordered
list cannot be completed, it's likely not safe to do at least some of the
following steps. For example, if you were not able to write the correct
configuration for a service, then starting it may open up a security
vulnerability.

Likewise, the Facebook cookbooks will err on the side of failing if something
seems wrong. This is both in line with the Chef philosophy we just outlined, but
also because this model assumes that code is being tested on real systems
before being released using something like
[taste-tester](https://github.com/facebook/taste-tester/) and that monitoring is
in place to know if your machines are successfully running Chef.

Here are some examples of this philosophy in practice:

* If a cookbook is included on a platform it does not support, we `fail`. It
  might seem like `return`ing in this case is reasonable but there is a good
  indication the runlist isn't as-expected, so it's a great idea to bail out
  before this machine is misconfigured
* If a configuration was passed in that we don't support, rather than ignore it
  we `fail`.

### Validation of inputs and `whyrun_safe_ruby_blocks`

Many cookbooks rely on the service underneath and the testing of the user to be
the primary validator of inputs. Is the software we just configured, behaving as
expected?

However, sometimes it's useful to do our own validation because there are
certain configurations we don't want to support, because the software may
accepted dangerous configurations we want to catch, or because the user could
pass us a combination of configurations that is conflicting or impossible to
implement.

In this model, however, this must be done at runtime. If your implementation is
done primarily inside of an internally-called resource, then this validation can
also be done there. However, if your implementation is primarily a recipe and
templates, doing the validation in templates is obviously not desireable. This
is where `whyrun_safe_ruby_blocks` come in.

Using an ordinary `ruby_block` would suffice to have ruby code run at runtime
to validate the attributes, however that means that the error would not be
caught in whyrun mode. Since this validation does not change the system, it is
safe to execute in whyrun mode, and that's why we use `whyrun_safe_ruby_block`s:
they are run in whyrun mode.

It is worth noting that this is also where you can take input that perhaps was
in a structure convenient for users and build out a different data structure
that's more convenient to use in your template.

### Implementating runtime-safe APIs

This model intentionally draws the complexity of Chef into the "core cookbooks"
(those implementing APIs) so that the user experience of maintaining systems is
simple and (usually) requires little more than writing to the node object.
However, the trade-off for that simplicity is that implementing the API properly
can be quite tricky.

How to do this is a large enough topic that it gets [its own
document](https://github.com/facebook/chef-utils/blob/master/Compile-Time-Run-Time.md).
However, some style guidance is also useful. This section assumes you have read
the aforementioned document.

The three main ways that runtime-safety is achieved are `lazy`, `templates`, and
`custom resources`. When should you use which?

The template case is fairly straight forward - if you have a template, simply read
the node object from the within the template source instead of using `variables`
on the template resource, and all data read is inherently runtime safe since
templates run at runtime.

But what about `lazy` vs `custom resources`? For example, in a recipe you might
do:

```ruby
package 'thingy packages' do
  package_name lazy {
    pkgs = 'thingy'
    if node['fb_thingy']['want_devel']
      pkgs << 'thingy-devel'
    end
    pkgs
  }
  action :upgrade
end
```

Where as inside of a custom resource you could instead do:

```ruby
pkgs = 'thingy'
if node['fb_thingy']['want_devel']
  pkgs << 'thingy-devel'
end

package pkgs do
  action :upgrade
end
```

Which one is better? There's not an exact answer, both work, so it's a style
consideration. In general, there are two times when we suggest a custom resource:

The first is when you need to loop over the node in order to even know what
resources to create. Since this isn't possible to (well, technically it's
possible with some ugliness, but by and large not using the standard DSL), this
must go into a custom resource. Example might be:

```ruby
# This MUST be inside of a custom resource!
node['fb_thingy']['instances'].each do |name, config|
  template "/etc/thingy/#{instance}.conf" do
    owner 'root'
    group 'root'
    mode '644'
    variables({:config => config})
  end
end
```

The second is when you're using `lazy` on the majority of the resources in
your recipe. If your recipe has 15 resources and you've had to pepper all of
them with `lazy`, it's a bit cleaner to just make a custom resource that you
call in your recipe.

It's important here to reiterate: we're **not** referring to using a Custom
Resource as an API, but simply making an internal custom resource, called
only by your own recipe, as a way to simplify runtime safety.

Outside of these two cases, you should default to implementations inside of
recipes. This is for a few reasons.

The first reason is that dropping entire implementations in custom resources leads
to confusion and sets a bad precdent for how runtime-safety works. For example,
consider the custom resource code we saw earlier where you assemble the package
list in "naked" ruby:

```ruby
pkgs = 'thingy'
if node['fb_thingy']['want_devel']
  pkgs << 'thingy-devel'
end
```

This code works fine in a resource, but serves as a bad reference for others -
since this absolutely won't work in a recipe (even though it'll run).

The second reason is that quite often implementations need both compile-time and
runtime code, and by blindly dropping the implementation into a custom resource,
you can often miss this and create bugs like this:

```ruby
# only safe because we're in a custom resource
packages = FB::Thingy.determine_packages(node)

package packages do
  action :upgrade
end

if node['fb_thingy']['want_cron']
  node.default['fb_cron']['jobs']['thingy_runner'] = {
    'time' => '* * * * *',
    'command' => '/usr/bin/thingy --quiet',
  }
end

service 'thingy' do
  action [:enable, :start]
end
```

Note here that while this code all seems reasoanble in a custom resource (`if`
statements are runtime safe when inside of a custom resource), that cronjob will
never get picked up, because you're using an API at runtime, but APIs must be
called at compiletime and consumed at runtime. In reality, this needs to be
in the recipe in order to work, and should look like this, in a *recipe*:

```ruby
package 'thingy packages' do
  package_name lazy { FB::Thingy.determine_packages(node) }
  action :upgrade
end

node.default['fb_cron']['jobs']['thingy_runner'] = {
  'only_if' => proc { node['fb_thingy']['want_cron'] },
  'time' => '* * * * *',
  'command' => '/usr/bin/thingy --quiet',
}

service 'thingy' do
  action [:enable, :start]
end
```

In general, always start your implementation as a recipe and then escalate to
Custom Resources where necessary.

## Debugging kitchen runs

You can setup kitchen using the same commands as in `.travis.yml`, but once
Chef runs you won't have access to connect, so modify
`fb_sudo/attributes/default.rb` and uncomment the kitchen block.

Then you can do `bundle exec kitchen login <INSTANCE>` after a failed
run, and sudo will be passwordless so you can debug.

## License

See the LICENSE file in this directory.
