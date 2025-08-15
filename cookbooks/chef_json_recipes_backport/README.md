chef_json_recipes_backport Cookbook
===================================
Cookbook to backport Chef JSON recipe functionality to older Chef Infra Client releases

This is based on the work done in the upstream Chef PRs:
- https://github.com/chef/chef/commit/78158cd2939ec5a6f0fa4a6fbddd55cd3586bc2f
- https://github.com/chef/chef/commit/bc4b8599fd3184536ecd67192c91b69f5798c617

Requirements
------------
Chef Infra Client 16 or higher (for monkeypatch to take effect)

The monkeypatch is not applied when the library is loaded on a Chef Infra
Client release that support JSON recipes

Attributes
----------

Usage
-----
Include this cookbook in your run's dependencies, and the backport should take
effect when the cookbook is loaded.

As this alters the Chef Infra Client `load_recipe` method, you are encouraged
to read the PRs/source to understand what is happening, and to test this before
rolling it out to your environments.
