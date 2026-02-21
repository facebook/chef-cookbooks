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

### Sync Process

1. Fetches latest commits from upstream repository
1. Identifies which commits haven't been synced yet
1. Attempts to cherry-pick each commit with an `Upstream-Commit` trailer
1. Creates/updates PRs for successfully synced commits
1. Creates GitHub issues for cookbooks with conflicts or local changes

### Command Process

1. Monitors PR comments for `#fbchefsync` commands (tag is configurable)
1. Parses and validates the command
1. Executes the requested operation (split or rebase)
1. Posts success/failure feedback as a PR comment

Configuration
-------------

### Bot Configuration File

Create a `fbchefsync_bot.yaml` file in your repository root:

```yaml
---
# Cookbooks to ignore during sync
# Use this sparingly. Defaults to fb_init/fb_sample_init since
# the naming will differ between your repo and the upstream
ignore_cookbooks:
  - fb_init
  - fb_init_sample

# Labels to apply to bot-created PRs. At least one is needed
# for the bot to find its PRs
pr_labels:
  - "fbchef_sync_bot"

# Labels to apply to bot-created issues. At least one is needed
# for the bot to find its Issues
issue_labels:
  - "fbchef_sync_bot"

# Label to apply to PRs that have been split. This is neded in order
# to not have the sync process clobber it with an un-split PR.
split_label: "fbchef_sync_bot_pr_split"
```

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
      upstream_remote_name: 'fb-upstream'
      python_version: '3.11'
      # optionally set dry_run when first testing...
    secrets:
      gh_token: ${{ secrets.GITHUB_TOKEN }}
```

**Workflow Inputs:**

- `upstream_repo_url`: URL of upstream repository (default:
  `https://www.github.com/facebook/chef-cookbooks.git`)
- `upstream_remote_name`: Name for the upstream git remote (default:
  `fb-upstream`)
- `upstream_branch`: Upstream branch to sync from (default: `main`)
- `base_branch`: Your base branch (default: `main`)
- `target_branch`: Target branch for sync (default: `main`)
- `pr_branch_prefix`: Prefix for automated PR branches (default: `fbchef_sync`)
- `python_version`: Python version to use (default: `3.11`)
- `dry_run`: If true, only logs actions without making changes (default:
  `false`)

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

Comment on any sync PR with these commands:

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
2. A new PR is created with the remaining commits
3. Both PRs are labeled with the `split_label` from your config
4. A success comment is posted with details

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
2. Rebases the PR branch onto it
3. Force-pushes the rebased branch (using `--force-with-lease` for safety)
4. Posts a success comment

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

Followed by a list of commands you can issue the bot it comments.

The `Upstream-Commit` trailers are critical for tracking which upstream commits
have been synced. You must ensure these tags stay in the commit message when
the PR is merged.

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

Issues are automatically labeled with `issue_labels` from your config.

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
