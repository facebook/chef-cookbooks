# Contributing to Facebook's Chef Cookbooks

## Our Development Process

This repository is synced from an internal repository. We absolutely accept
pull requests and will deal with the merging appropriately.

We use Foodcritic for Chef correctness testing and Rubocop for Ruby style
linting. Our rule sets are synced both internally and externally to ensure
consistent code quality and style for all.

## Contributor License Agreement ("CLA")

In order to accept your pull request, we need you to submit a CLA. You only
need to do this once to work on any of Facebook's open source projects.

Complete your CLA here: <https://code.facebook.com/cla>

## Pre-requisites

First, thanks for your interest in contributing, we welcome pull requests!

Before sending a pull request to this repo it's important to remember that the
attribute-driven APIs here are a very different model than other community
cookbooks. In order to build that model, there's a specific way cookbooks need
to be written.

We highly recommend you ensure you read the [README.md](README.md) and
[Philosphy.md](https://github.com/facebook/chef-utils/blob/main/Philosophy.md).
We also recommend you've setup an environment that uses our run-list ordering
(core cookbooks first, everything else after).

Finally, please ensure you follow the 3-phase approach:

 * `attributes/*` set up an API and never touch other cookbook's attributes
 * `recipes/*` set up resources (such as templates or services), and use
   APIs (read: set attributes for other cookbooks)
 * Attributes are only ever consumed at `runtime` (aka `converge time`).
   Examples include `templates`, `ruby_blocks`, `whyrun_safe_ruby_blocks`, or
   `providers`.

## Issues

We use GitHub issues to track public bugs. Please ensure your description is
clear and has sufficient instructions to be able to reproduce the issue.

Facebook has a [bounty program](https://www.facebook.com/whitehat/) for the
safe disclosure of security bugs. In those cases, please go through the process
outlined on that page and do not file a public issue.

## Sending a pull request

Have a fix or feature? Awesome! When you send the pull request we suggest you
include some output of an applicable chef run.

If it's a new API (attribute), please ensure it's documented in the proper
cookbook README.

We will hold all contributions to the same quality and style standards as the
existing code.

### New Cookbooks

We'd like to keep this repo focused on "core" cookbooks which manage the base
OS. If you would like to contribute such a cookbook, we recommend you start by
filing an Issue first to avoid duplicating effort (we may have one that we can
try to open-source, or other people may be writing one) before working on it.

If you'd like to contribute a cookbook that doesn't fall in that category (e.g.
managing desktop things or other services), then we suggest you point us to a
PR on a repo where you'd like to keep it and we'll be happy to review it and
add a pointer to your repo in our [UNIVERSE.md](https://github.com/facebook/chef-cookbooks/blob/main/UNIVERSE.md) file.

We use the `fb_` prefix to denote cookbooks that fit this model and come from
this repo, but feel free to publish cookbooks elsewhere that leverage this
model and use other prefixes.

## License

By contributing to this repository, you agree that your contributions will be
licensed under its Apache 2.0 license.
