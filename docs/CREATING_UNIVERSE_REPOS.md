How to create a Universe repo
=============================

This document covers how to create a universe repo. The GitHub Actions
workflows in this repo have been factored out for reusablity, to make sure all
repos we reference will work well with the Facebook core cookbooks.

**BEFORE YOU START**: You'll need a prefix for your cookbooks. Check
[UNIVERSE.md](../UNIVERSE.md) to ensure you're using a unique one.

Requirements
------------

### Repo Layout

The repository should be layed out with the following top-level items:

* `cookbooks/` - a directory in which your cookbooks live
* `scripts/` - a directory for local scripts
* `README.md` - a README which should include specific things mentioned below
* `CONTRIBUTING.md` - a document on how to contribute to your repo
* `LICENSE` - A license file, see below for details

We also recommend `CODE_OF_CONDUCT.md`.

### API Requirements

Your cookbooks must follow the overall Facebook API model, which includes,
but is not limited to:

* The API is initialized in `attributes/default.rb`
* The API is
  [runtime-safe](https://github.com/facebook/chef-utils/blob/main/Compile-Time-Run-Time.md)
* The API, wherever possible, owns entire configuration 'systems' instead of
  'settings' (ala "all sysctls" instead of "a single sysctl") to allow for
  automatic cleanup (see point number 2 under [APIs](../README.md#APIs))

### Other Requirements

The format of your `README.md` is up to you, but it **must** reference this
repo, and **should** mention the Philosophy doc and this repos README doc. This
repo includes a [sample README.md](samples/README.md) for you to start with.

We **highly** recommend your license be Apache 2.0 to match the rest of the
Chef ecosystem, however, we **require** it be compatible with Apache 2.0.

How you choose to handle CLA/Copyright is up to you, but we recommend the
[Developer Certificate of
Origin](https://www.chef.io/blog/introducing-developer-certificate-of-origin)
approach and the [DCO Action](https://github.com/tim-actions/dco) to check it.

Your repository **must** use our [reusable Kitchen
workflow](../../.github/workflows/reusable-kitchen-tests.yml) and [reusable
Lint/Unit workflow](.github/workflows/reusable-ci.yml) (see [docs
below](#reusable-github-actions-workflows)).

Setting up your Repo
--------------------

* Symlink (or copy, if you prefer)
  [run_upstream_script](../scripts/run_upstream_script) from this repo into
  your repo's `scripts/` directory.
* Copy the [sample README.md](samples/README.md) to your repo, modify to taste.
  You will need to replace `YOUR_ORG`, `YOUR_REPO`, and `YOUR_TITLE`, at a
  minimum.
* Copy the [sample ci.yml](samples/workflows/ci.yml) and [sample
  kitchen.yml](samples/workflows/kitchen.yml) to your repo's
  `.github/workflows` directory, and modify to taste
* If you want to use DCO, copy [sample dco.yml](samples/workflows/dco.yml) to
  your repo's `.github/workflows` directory.
* Put your cookbooks in your `cookbooks/` directory
* Popluate your `LICENSE` and `CONTRIBUTING.md` file

Once that repo is up and working, create a PR in this repo to add your repo to

* [UNIVERSE.md](../UNIVERSE.md)
* [repo_stats_config.rb](../community_meetings/repo_stats_config.rb)

Testing Locally
---------------

We provide a [run_upstream_script](../scripts/run_upstream_script) script which
will do the work of properly running the upstream scripts for your repo. It
basically figures out how to run whatever script you want, takes the arguements
you pass it, changes directory into your checkout of this upstream repo so that
it has the relevant configs, plugins, etc., and modifies or adds any arguements
to point it back to what you called it with.

Any filename args should be passed **after** a `--`

So for example if you run, from the root of your directory:

```shell
./scripts/run_upstream_script run_mdl
```

It'll run:

```shell
cd ../chef-cookbooks
./scripts/run_mdl $path_to_your_repo
```

Or, if you run this from within `cookbooks/zz_foo`:

```shell
../../scripts/run_upstream_script run_chefspec -- .
```

Then it will run:

```shell
cd ../../../chef-cookbooks
./scripts/run_chefspec $path_to_your_repo/cookbooks/zz_foo/.
```

If no file-like arguments are passed, it'll pass the root directory of your
repo as the arguement.

Since the script aims to be completely transparent, it does not, itself,
accept any arguements, but you may specify DEBUG=1 in the environment to
get debugging information out of it:

```shell
DEBUG=1 ./scripts/run_upstream_script ...
```

Reusable GitHub Actions Workflows
---------------------------------

### Kitchen

The reusable kitchen workfow is required and takes several inputs:

* `universe` - For universe repos, you must set this to `true` (it defaults to
  false, for this repo).
* `suite` - By default, this is `default`, but if you want to change the
  Kitchen suite that runs (to change the runlist, mostly), you can change this
  here.
* `additional_os_list` - The main OSes that Meta's cookbooks are tested on is a
  requirement for all Universe repos, but you may add additional ones here in
  the form of a JSON string array, e.g. `'["some-os", "some-other-os"]'`.
* `kitchen_local_yaml` - An optional filename to pass in with additional
  kitchen configs. This is required both if you specify additional OSes, but
  also if you specify a different suite.

The minimal job description would be:

```yaml
kitchen:
  uses: facebook/chef-cookbooks/.github/workflows/reusable-kitchen-tests.yml@main
  with:
    universe: true
```

But let's say you wanted a different runlist. You could create a `.kitchen.local.yaml` with:

```yaml
suites:
  - name: local
    run_list:
      - recipe[my_base_recipe]
```

And then pass in this under `with`:

```yaml
suite: local
kitchen_local_yaml: .kitchen.local.yaml
```

Similarly defining additional OSes, will require defining them under
`platforms` in your local kitchen file when passing them into
`additional_os_list`.

### CI (aka lint and unit testing)

The reusable CI workflow is required and takes several inputs:

* `universe` - For universe repos, you must set this to `true` (it defaults to
  false, for this repo).
* `additional_ruby_versions` - The main Ruby versions that Meta's cookbooks are
  tested on is a requirement for all Universe repos, but you may add additional
  ones here in the form of a JSON string array, e.g. `'["3.4", "3.5"]'`.

The minimal job description would be:

```yaml
ci:
  uses: facebook/chef-cookbooks/.github/workflows/reusable-ci.yml@main
  with:
    universe: true
```
