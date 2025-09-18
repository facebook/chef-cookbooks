Community Meetings
==================

Progress runs a weekly Community Meeting in the `#community-meetings` channel
in the [Chef Community Slack](https://community-slack.chef.io/). Currently it's
Thursday's at 9am, but you can see the latest information
[here](https://community.chef.io/).

In those meetings, Progress teams give updates, and then community members
are invited to give updates. As part of being part of the community, we give
an update on FB-API-related repos - this and UNIVERSE repos.

This directory provides everything required to easily do so.

Running the report
------------------

In order to run the report, checkout
[oss-stats](https://github.com/jaymzh/oss-stats/) somewhere of your choosing.
For the purposes of this, we will assume it's checked out at the same level as
this repo.

NOTE: You shouldn't run the report until Wednesday after noon.
NOTE: If you run it Thursday, you'll need to do so manually (see below)
and pass in `--date` to `repo_stats`.

Then, in this directory, simply run:

```shell
./run_report.sh
```

Note that you will need rbenv or rvm setup with ruby 3.2+.

Take the output and post it to slack. Feel free to schedule it
for 9:15am Thursday morning.

### Manual generation

If the script fails for some reason, or if you need to pass in specific
options to `repo_stats`, simply run:

```shell
<path_to_oss_stats>/bin/repo_stats
```

Then, take the output, put it at the end of this header:

```text
:facebook: :cook: *_FB ATTRIBUTE-API COOKBOOKS UPDATE_* :facebook: :cook:

Welcome to the weekly report - this report includes both the primary
Facebook repo as well as other repos (requested to be part of this report)
that implement FB APIs.
```

and post it into Slack.

FAQ
---

*Why not add `oss-stats` to Gemfile, and run it from this repo?*

Because `oss-stats` requires ruby 3.2+, but this repo still requires
ruby 3.1.
