FBChef Sync Bot
===============

Automated bot for syncing upstream Facebook Chef cookbooks to your downstream
repo and managing pull requests.

Overview
--------

The FBChef Sync Bot automates the process of keeping your Chef cookbook
repository in sync with Facebook's upstream Chef cookbooks. It:

- **Automatically syncs** commits from the upstream repository
- **Creates PRs** with detailed commit information and trailers
- **Detects conflicts** and creates GitHub issues for cookbooks with local
  changes
- **Supports interactive commands** for PR management (split, rebase)
- **Provides feedback** via PR/issue comments on command success or failure

How It Works
------------

The bot runs in two modes:

1. **Sync Mode** (scheduled/triggered): Fetches upstream commits and
   creates/updates sync PRs
1. **Command Mode** (comment-triggered): Responds to commands on PRs to split
   or rebase them

The bot supports syncing from **multiple upstream repositories**
simultaneously, with each upstream identified by a cookbook prefix (e.g.,
`fb_`, `pd_`). Each upstream is tracked independently with its own commit
trailers, PRs, and issues.

### Sync Process

1. Fetches latest commits from all configured upstream repositories
1. For each upstream:
   - Identifies which commits haven't been synced yet (using upstream-specific
     trailers)
   - Attempts to cherry-pick each commit with the appropriate trailer
   - Creates/updates PRs for successfully synced commits
   - Creates GitHub issues for cookbooks with conflicts or local changes
1. Each upstream gets its own sync PR branch and is processed independently

### Command Process

1. Monitors PR comments for bot commands (tag is configurable, default:
   `#fbchefsync`)
1. Automatically detects which upstream a PR belongs to based on branch name or
   trailers
1. Parses and validates the command
1. Executes the requested operation (split or rebase)
1. Posts success/failure feedback as a PR comment

Configuration
-------------

### Bot Configuration File

Create a `fbchefsync_bot.yaml` file in your repository root. See
[`fbchefsync_bot.yaml.example`](fbchefsync_bot.yaml.example) for a complete
annotated example.

**Basic structure:**

```yaml
---
# Bot label for PRs and issues (singular label for both)
# Required: The bot needs at least one label to identify its PRs and issues
bot_label: "fbchef_sync_bot"

# Label applied to PRs that have been split
# This prevents the sync process from overwriting split PRs
split_label: "fbchef_sync_bot_pr_split"

# Bot command prefix (optional, defaults to "#fbchefsync")
bot_command_prefix: "#fbchefsync"

# Additional universe upstreams (optional)
# Add more upstreams here for syncing from multiple repositories
# Each upstream must have a unique prefix
# Remote names are automatically: {prefix}upstream (e.g., pd_upstream)
universe_upstreams:
  pd-chef-cookbooks:             # Name doesn't matter, just needs to be unique
    prefix: pd_                  # Must be unique across all upstreams
    repo_url: https://github.com/example/pd-chef-cookbooks.git
    branch: main                 # Optional, defaults to 'main'
    ignore_cookbooks: []         # Optional, defaults to empty list

  # You can add more upstreams:
  # another-upstream:
  #   prefix: xyz_
  #   repo_url: https://github.com/example/xyz-cookbooks.git
  #   ignore_cookbooks:
  #     - xyz_test
```

Note that while you should not need to, if for some strange reason, you want to
change the configuration for the primary FB upstream repo, you can use
`upstream_overrides`, like so:

```yaml
upstream_overrides:
  ignore_cookbooks:
    - fb_init
    - fb_init_sample
```

All the same things that can be specified for universe repos can be specified
in `upstream_overrides` - but again, you probably don't want to.

**Important Notes:**

- **Automatic Remote Management**: The bot automatically initializes git
  remotes for all configured upstreams using the pattern `{prefix}upstream`
  (e.g., `fb_upstream`, `pd_upstream`). You don't need to manually set up
  remotes.
- **Unique Prefixes Required**: Each upstream must have a unique prefix. The
  bot validates this on startup and will fail if duplicates are found.
- **Commit Trailers**: Each upstream uses its own trailer key for tracking:
   - Primary upstream (typically `fb_`): uses `Upstream-Commit`
   - Other upstreams: use `{prefix}Upstream-Commit` (e.g., `pd_Upstream-Commit`)
- **Separate PRs**: Each upstream gets its own sync PR with a branch name like
  `sync/{prefix}update` (e.g., `sync/fb_update`, `sync/pd_update`)

Initial Setup & Onboarding
---------------------------

When you first run the bot or add a new upstream, it enters **onboarding mode**
to establish the initial sync baseline.

### First Run

1. Create your `fbchefsync_bot.yaml` configuration file with at least one
   upstream
1. Set up the GitHub Actions workflows (see below)
1. Trigger the sync workflow manually or wait for the schedule
1. The bot will detect that no upstream pointer exists and:
   - Analyze your existing cookbooks for each upstream
   - Detect the baseline commit SHA in the upstream repository
   - Create an onboarding PR with an empty commit containing the baseline
     trailer
1. Review and merge the onboarding PR
1. The next sync run will begin syncing new commits from that baseline forward

### Adding a New Upstream

When you add a new upstream to `universe_upstreams`:

1. Update your `fbchefsync_bot.yaml` with the new upstream configuration
1. Ensure the prefix is unique
1. Run the sync workflow
1. The bot will create a separate onboarding PR for the new upstream
1. Merge the onboarding PR to enable syncing for that upstream

### Force Bootstrap

If you need to reset the baseline for an upstream, you can use the
`--force-bootstrap` flag (requires code modification or custom workflow
trigger). This will re-detect the baseline and create a new onboarding PR.

Workflow Setup
--------------

The bot requires two GitHub Actions workflows in your repository.

### 1. Upstream Sync Workflow

Create `.github/workflows/fbchefbot-sync.yml`:

```yaml
name: FBChefSync Bot - Upstream Sync

on:
  workflow_dispatch:  # Manual trigger from GitHub UI
  # We run on a schedule, but when one of our PRs or conflict Issues
  # is closed, we want to immediately run to get the next batch of
  # commits up for review, so listen for closed PRs and issues
  #
  # However, we don't use pull_request as we don't want to run in the
  # context of the PR, we want to run in the main context, so
  # pull_request_target.
  pull_request_target:
    types: [closed]
    branches:
      - main
  issues:
    types: [closed]
  schedule:
    - cron: '0 6 * * *'  # Daily at 06:00 UTC

# don't let multiple instances of the bot run at the same
# time, that'd mess things up.
concurrency:
  group: chef-sync-bot
  cancel-in-progress: false

jobs:
  sync:
    name: Run daily sync
    uses: ./.github/workflows/reusable-fbchefsync-bot.yml
    with:
      python_version: '3.11'
      # optionally set dry_run when first testing...
      # dry_run: true
    secrets:
      gh_token: ${{ secrets.GITHUB_TOKEN }}
```

**Workflow Inputs:**

- `base_branch`: Your repository branch (default: `main`)
- `pr_branch_prefix`: Prefix for automated PR branches (default: `fbchef_sync`)
- `python_version`: Python version to use (default: `3.11`)
- `dry_run`: If true, only logs actions without making changes (default:
  `false`)

**Note:** Upstream repository URLs, branches, and remote names are now
configured in `fbchefsync_bot.yaml` rather than as workflow inputs. The bot
automatically manages git remotes for all configured upstreams.

### 2. Command Handler Workflow

Create `.github/workflows/fbchefbot-commands.yml`:

```yaml
name: FBChefSync Bot - Command handler

on:
  issue_comment:
    types: [created]

concurrency:
  group: chef-sync-bot
  cancel-in-progress: false

jobs:
  commands:
    name: Handle commands
    uses: ./.github/workflows/reusable-fbchefsync-bot.yml
    with:
      python_version: '3.11'
    secrets:
      gh_token: ${{ secrets.GITHUB_TOKEN }}
```

This workflow automatically handles comments on PRs that contain bot commands.

Bot Commands
------------

Comment on any sync PR with these commands. The bot automatically detects which
upstream the PR belongs to based on the branch name and commit trailers, so
commands work seamlessly across multiple upstreams.

### Split Command

Split a PR into two separate PRs. Use this when you want to merge part of a
sync PR while keeping the rest for later.

**Syntax:**

```text
#fbchefsync split <start-sha>-<end-sha>
```

**Parameters:**
- `start-sha`: First 7-40 characters of the starting commit SHA
- `end-sha`: First 7-40 characters of the ending commit SHA

**Requirements:**
- The range must be contiguous from one end of the PR (beginning or end), not
  from the middle
- The SHAs must exist in the PR's `Upstream-Commit` trailers

**Example:**

```text
#bot split abc1234-def5678
```

**What happens:**
1. The original PR is rewritten to contain only the specified range of commits
1. A new PR is created with the remaining commits
1. Both PRs are labeled with the `split_label` from your config
1. A success comment is posted with details

**Success Response:**

```text
✅ Split completed successfully!

- Updated this PR with 3 commit(s)
- Created new PR #123 with 5 commit(s)
```

### Rebase Command

Rebase the PR onto the latest base branch. Use this when the base branch has
moved ahead and you want to update the PR.

**Syntax:**

```text
#fbchefsync rebase
```

**What happens:**
1. Fetches the latest base branch
1. Rebases the PR branch onto it
1. Force-pushes the rebased branch (using `--force-with-lease` for safety)
1. Posts a success comment

**Success Response:**

```text
✅ Rebase completed successfully!

- Rebased 8 commit(s) onto latest `main`
- Branch `fbchef_sync/abc1234` has been updated
```

**Conflict Handling:**
If the rebase encounters conflicts, the bot posts an error comment with manual
resolution instructions:

```text
❌ Failed to execute command `rebase`

**Error:** Rebase failed with conflicts. Please resolve conflicts manually.
You may need to checkout the branch locally and run:

git checkout fbchef_sync/abc1234
git rebase origin/main
# Resolve conflicts
git rebase --continue
git push --force-with-lease
```

### Unknown Command Response

If you use an unrecognized command, the bot responds with:

```text
❌ Unknown command: `yourcommand`

Supported commands:
- `#bot split <sha1>-<sha2>` - Split a PR into two PRs
- `#bot rebase` - Rebase the PR onto the latest base branch
```

PR Structure
------------

Sync PRs created by the bot have a specific structure:

The title will be:

```text
Sync upstream (N commits)
```

The body will be:

```markdown
Syncing upstream commits. The PRs are listed below. You can comment in this PR
with commands see below. Also, this description is build for squash-merge, make
sure you keep all the `Upstream-Commit` trailers in tact.

* cookbook_name: Short commit description
  * Upstream-Commit: abc123...

* another_cookbook: Another commit description
  * Upstream-Commit: def456...
```

Followed by a list of commands you can issue the bot in comments.

**Commit Trailers:**

The trailers are critical for tracking which upstream commits have been synced.
You must ensure these tags stay in the commit message when the PR is merged.

- **Primary upstream** (typically `fb_` prefix): uses `Upstream-Commit`
- **Other upstreams**: use `{prefix}Upstream-Commit` (e.g.,
  `pd_Upstream-Commit`)

**Multiple Upstreams:**

When syncing from multiple upstreams, each upstream gets its own separate PR:
- Branch name: `sync/{prefix}update` (e.g., `sync/fb_update`, `sync/pd_update`)
- Each PR only contains commits for cookbooks with that upstream's prefix
- Trailers use the upstream-specific format to avoid conflicts

GitHub Issues
-------------

The bot creates GitHub issues when it detects:

1. **Sync conflicts**: When cherry-picking upstream commits fails
1. **Local changes**: When cookbooks have been modified locally

Issues include:
- Commit SHA that caused the conflict
- Affected cookbooks
- Conflict details (if available)
- Required actions

Issues are automatically labeled with `bot_label` from your config. When
syncing from multiple upstreams, issue titles will indicate which upstream is
affected.

Permissions
-----------

The bot requires the following GitHub permissions:

- **Contents**: Write (to create branches and push commits)
- **Pull Requests**: Write (to create and manage PRs)
- **Issues**: Write (to create conflict issues)

These are provided by the `GITHUB_TOKEN` secret in GitHub Actions, which is
automatically available.

Dry Run Mode
------------

Test the bot without making actual changes by setting `dry_run: true` in the
workflow:

```yaml
with:
  dry_run: true
```

In dry-run mode:
- No branches are created or pushed
- No PRs are created
- No issues are filed
- No comments are posted
- All actions are logged with `[dry-run]` prefix

This is useful for testing bot changes in PRs before merging to main.
FAQ & Troubleshooting
---------------------

### How do I sync from multiple upstream repositories

Add additional upstreams to the `universe_upstreams` section of your
`fbchefsync_bot.yaml`. Each upstream must have:
- A unique `prefix` that matches your cookbook naming convention
- A `repo_url` pointing to the upstream repository
- Optionally, a `branch` (defaults to `main`) and `ignore_cookbooks` list

The bot will automatically:
- Create and manage git remotes for each upstream
- Generate separate sync PRs for each upstream
- Track commits independently using prefix-specific trailers

### What if I already have git remotes set up

The bot validates existing remotes on startup. If a remote with the expected
name already exists, it checks that the URL matches your configuration. If
there's a mismatch, the bot will fail with an error message asking you to fix
the remote URL manually.

### Can I have cookbooks from different upstreams in the same repository

Yes! That's the primary use case for multi-upstream support. Each cookbook is
identified by its prefix (e.g., `fb_apache`, `pd_nginx`), and the bot syncs
them from their respective upstream repositories independently.

### What happens if two upstreams have the same cookbook name

Upstreams must have unique prefixes specifically to avoid this. Cookbooks are
identified by their full name including the prefix. If you have `fb_apache` and
`pd_apache`, they're treated as completely separate cookbooks.

### How do I remove an upstream

Simply remove it from your `fbchefsync_bot.yaml` configuration. The bot will
stop syncing from that upstream on the next run. The git remote will remain
(the bot doesn't delete remotes), but it won't be used. You can manually remove
it with `git remote remove <remote-name>` if desired.

### Can I temporarily disable syncing for one upstream

Yes, you can:
1. Comment out or remove that upstream from `universe_upstreams`
1. Or add all its cookbooks to `ignore_cookbooks` for that upstream

The first approach is cleaner if you want to completely pause syncing.

### What if I want different branches for different upstreams

Each upstream in your config can specify its own `branch` parameter:

```yaml
upstream_overrides:
  prefix: fb_
  repo_url: https://github.com/facebook/chef-cookbooks.git
  branch: main

universe_upstreams:
  experimental:
    prefix: exp_
    repo_url: https://github.com/example/experimental-cookbooks.git
    branch: develop  # Different branch
```
