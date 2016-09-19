# Facebook Cookbooks Suite

[![Build Status](https://travis-ci.org/facebook/chef-cookbooks.svg)](http://travis-ci.org/facebook/chef-cookbooks)

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


## APIs

Unlike other cookbook models, we do not use resources as APIs, we use the node
object. Configuration is modeled in arrays and hashes as closely and thinly as
possible to the service we are configuring. Ideally, you should only have to
read the docs to the service to configure it, not the docs to the cookbook.
 
For example, if the service we are configuring has a key-value pair
configuration file, we will provide a simple hash where keys and values will be
directly put into the necessary configuration file.

There are two reasons we use attribute-driven APIs:

1. Since our cookbooks are ordered least specific (core team that owns Chef) to
   most specific (the team that owns this machine or service) it means that the
   team who cares about this specific instance to always override anything. This
   enables stacking that is not possible in many other models. For example, you
   can have a runlist that looks like:

   * Core cookbooks (the ones in this repo)
   * Site/Company cookbooks (site-specific settings)
   * Region cookbooks (overrides for a given region/cluster)
   * Application Category cookbooks (webserver, mail server, etc.)
   * Specific Application cookbook ("internal app1 servier")

   So let's say that you want a specific amount of shared memory by default,
   but in some region you know you have different size machines, so you shrink
   it, but web servers need a further different setting, and then finally some
   specific internal webserver needs an even more specific setting... this all
   just works.

   Further, a cookbook can see the value that was set before it modifies things,
   so the 'webserver' cookbook could look to see if what the value was (small or
   large) before modifying it and adjust it accordingly (so it could be relative
   to the size of memory that the 'region' cookbook set.

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
   `/etc/cron.d/fb_crontab` - one you delete the lines adding a cronjob, since
   they are just entries in a hash, when the template is generated on the next
   Chef run, those crons go away.

   Alternatively, consider a sysctl set by the "site" cookbook, then overwritten
   but a later cookbook. When they remove that code, the entry in the hash is
   now that set by the "site" cookbook. Automatically it falls back to the
   next-most-specific value
 

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

Grab a copy of the repo, rename `fb_init_sample` to fb_init, and follow the
instructions in the README.md (coordinating guidance is in comments in the
default recipe).

# test phild
