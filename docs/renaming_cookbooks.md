How to rename a cookbook
========================

If you want to import a new cookbook that has a name collision with an existing
cookbook, here are the steps for doing so. These sections are broken up so that
they may be done atomically as separate commits.

Double-write attribute to a new top-level key
---------------------------------------------

In this case, we will double-write to a key that matches what we will rename
our old cookbook to (`fb_foo_old`).

Example:

```ruby
# before
node.default['fb_foo']['bar'] = value

# after
node.default['fb_foo_old']['bar'] = node.default['fb_foo']['bar'] = value
```

For this, we recommend using the UpdateToplevelNodeAttribute Cookstyle cop in
this repo.

Change attribute-consuming cookbooks to use new attribute keys
--------------------------------------------------------------

```ruby
# before
read_value = node['fb_foo']['bar']

# after
read_value = node['fb_foo_old']['bar']
```

Copy old cookbook to temporary cookbook name
--------------------------------------------

- Copy, recursively: `fb_foo` to `fb_foo_old`
- In `fb_foo_old`:
   - Update Class/Module/Constant names
   - Update `metadata.rb`/`metadata.json`
   - Update `README.md`

Change references from old cookbook name to temporary cookbook name
-------------------------------------------------------------------

You will need to change:
- dependencies in consumer metadata files
- `include_recipe` calls
- role run lists
- resource `cookbook` references (See `cookbook` property on
  [cookbook_file](https://docs.chef.io/resources/cookbook_file/#properties)
- documentation (wikis, other READMEs, etc.)

For updating `include_recipe` calls we recommend the UpdateIncludeRecipe
Cookstyle cop in this repo.

Delete old cookbook
-------------------

Now that all consuming cookbooks and run lists have `fb_foo_old`, you should be
able to safely remove `fb_foo`.

Add new cookbook to your repo
-----------------------------

Now that the old `fb_foo` is removed, you can import the new `fb_foo` that you
want to pull in.
