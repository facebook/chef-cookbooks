#!/usr/bin/env python3

# Copyright (c) 2016-present, Facebook, Inc.
# Copyright (c) 2016-present, Phil Dibowitz
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys
import subprocess
import re
import json
import logging
from typing import List, Optional, Tuple, Dict
from pathlib import Path
import argparse
import yaml

# Module-level logger for utility functions
logger = logging.getLogger(__name__)


def load_config() -> Dict:
    """
    Load configuration from line-cook.yaml if it exists.
    Returns a dict with config values (with defaults if file doesn't exist).
    """
    config_path = Path("line-cook.yaml")
    default_config = {
        "bot_label": "line-cook",
        "split_label": "line-cook-pr-split",
        "bot_command_prefix": "#linecook",
        "upstream_overrides": {
            "prefix": "fb_",
            "repo_url": "https://www.github.com/facebook/chef-cookbooks.git",
            "ignore_cookbooks": ["fb_init", "fb_init_sample"],
        },
        "universe_upstreams": {},
    }

    if not config_path.exists():
        logger.debug(f"Config file {config_path} not found, using defaults")
        return default_config

    try:
        with open(config_path, "r") as f:
            user_config = yaml.safe_load(f) or {}
        logger.info(f"Loading config from {config_path}")

        # Merge with defaults - be careful with nested dicts
        config = {**default_config}
        for key, value in user_config.items():
            if key == "upstream_overrides" and isinstance(value, dict):
                # Merge upstream_overrides with defaults
                config["upstream_overrides"] = {
                    **default_config["upstream_overrides"],
                    **value,
                }
            else:
                config[key] = value

        # Validate the configuration
        _validate_config(config)

        logger.debug(f"Config loaded: {config}")
        return config
    except Exception as e:
        logger.warning(
            f"Error loading config file {config_path}: {e}, using defaults"
        )
        return default_config


def _validate_config(config: Dict) -> None:
    """
    Validate the configuration structure.
    Raises ValueError if configuration is invalid.
    """
    # Collect all prefixes to check for duplicates
    prefixes = []

    # Add primary upstream prefix
    primary = config.get("upstream_overrides", {})
    if "prefix" in primary:
        prefixes.append(primary["prefix"])

    # Add universe upstream prefixes
    universe = config.get("universe_upstreams", {})
    if universe:
        for name, upstream_config in universe.items():
            if not isinstance(upstream_config, dict):
                raise ValueError(
                    f"Invalid universe_upstreams entry '{name}': must be a dict"
                )
            if "prefix" not in upstream_config:
                raise ValueError(
                    f"Invalid universe_upstreams entry '{name}': missing required 'prefix'"
                )
            if "repo_url" not in upstream_config:
                raise ValueError(
                    f"Invalid universe_upstreams entry '{name}': missing required 'repo_url'"
                )
            prefixes.append(upstream_config["prefix"])

    # Check for duplicate prefixes
    if len(prefixes) != len(set(prefixes)):
        duplicates = [p for p in prefixes if prefixes.count(p) > 1]
        raise ValueError(
            f"Duplicate upstream prefixes detected: {list(set(duplicates))}. "
            f"Each upstream must have a unique prefix."
        )


def run(cmd: List[str], check: bool = True) -> str:
    logger.debug(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    logger.debug(f"Command exit code: {result.returncode}")
    if check and result.returncode != 0:
        logger.error(f"Command failed: {' '.join(cmd)}")
        logger.debug(f"Command stderr: {result.stderr}")
        raise RuntimeError(f"{' '.join(cmd)}\n{result.stderr}")
    return result.stdout.strip()


def git(*args: str) -> str:
    logger.debug(f"Git command: git {' '.join(args)}")
    return run(["git", *args])


def try_git(*args: str) -> Tuple[bool, str, str]:
    logger.debug(f"Try git command: git {' '.join(args)}")
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    logger.debug(f"Try git exit code: {result.returncode}")
    return result.returncode == 0, result.stdout, result.stderr


class LineCook:
    """
    Line Cook - Bot to sync upstream cookbooks to local fork.
    """

    def __init__(
        self,
        config: Dict,
        dry_run: bool = False,
        force_bootstrap: bool = False,
    ):
        self.config = config
        self.dry_run = dry_run
        self.force_bootstrap = force_bootstrap

        self.base_branch = os.environ.get("BASE_BRANCH", "main")
        self.pr_branch_prefix = os.environ.get("PR_BRANCH_PREFIX", "line-cook")
        self.target_remote = os.environ.get("TARGET_REMOTE", "origin")
        self.github_event_name = os.environ.get("GITHUB_EVENT_NAME")
        self.github_event_path = os.environ.get("GITHUB_EVENT_PATH")

        self.logger = logging.getLogger(__name__)

        # Setup upstream configurations
        self._setup_upstreams()

        # Initialize and validate git remotes
        self._initialize_remotes()

        # Verify required labels exist in the repository
        self._check_labels_exist()

    def _setup_upstreams(self) -> None:
        """
        Setup upstream configurations from config.
        Creates self.upstreams dict with all upstream configurations.
        """
        self.upstreams = {}

        # Primary upstream (from upstream_overrides or defaults)
        primary_config = self.config.get("upstream_overrides", {})
        primary_prefix = primary_config.get("prefix", "fb_")
        primary_repo_url = primary_config.get(
            "repo_url", "https://www.github.com/facebook/chef-cookbooks.git"
        )
        primary_ignore = primary_config.get(
            "ignore_cookbooks", ["fb_init", "fb_init_sample"]
        )
        primary_branch = primary_config.get("branch", "main")

        # Remote name is prefix-based, just like universe upstreams
        primary_remote = f"{primary_prefix}upstream"

        self.upstreams[primary_prefix] = {
            "prefix": primary_prefix,
            "repo_url": primary_repo_url,
            "remote": primary_remote,
            "branch": primary_branch,
            "ignore_cookbooks": primary_ignore,
            "is_primary": True,
            "trailer_key": "Upstream-Commit",
        }

        # Universe upstreams
        universe_upstreams = self.config.get("universe_upstreams", {})
        for name, upstream_config in universe_upstreams.items():
            prefix = upstream_config["prefix"]
            repo_url = upstream_config["repo_url"]
            ignore = upstream_config.get("ignore_cookbooks", [])

            # Remote name is prefix-based (e.g., "pd_upstream")
            remote = f"{prefix}upstream"
            branch = upstream_config.get("branch", "main")

            # Trailer key incorporates the prefix (e.g., "pd_Upstream-Commit")
            trailer_key = f"{prefix}Upstream-Commit"

            self.upstreams[prefix] = {
                "prefix": prefix,
                "repo_url": repo_url,
                "remote": remote,
                "branch": branch,
                "ignore_cookbooks": ignore,
                "is_primary": False,
                "trailer_key": trailer_key,
            }

        self.logger.debug(
            f"Configured {len(self.upstreams)} upstreams: {list(self.upstreams.keys())}"
        )

    def _initialize_remotes(self) -> None:
        """
        Initialize and validate git remotes for all configured upstreams.

        For each upstream:
        - If remote doesn't exist, add it
        - If remote exists, validate URL matches configuration
        - Raise error if existing remote URL doesn't match expected URL
        """
        for prefix, upstream_config in self.upstreams.items():
            remote_name = upstream_config["remote"]
            expected_url = upstream_config["repo_url"]

            # Check if remote exists
            success, existing_url, stderr = try_git(
                "remote", "get-url", remote_name
            )

            if success:
                # Remote exists, validate URL
                existing_url = existing_url.strip()
                if existing_url != expected_url:
                    raise RuntimeError(
                        f"Remote '{remote_name}' exists with URL '{existing_url}' "
                        f"but expected '{expected_url}'. Please fix the remote URL manually."
                    )

                self.logger.info(
                    f"Validated remote '{remote_name}' with URL '{expected_url}'"
                )
            else:
                # Remote doesn't exist, add it
                self.logger.info(
                    f"Adding remote '{remote_name}' with URL '{expected_url}'"
                )
                git("remote", "add", remote_name, expected_url)

    def _check_labels_exist(self) -> None:
        """
        Verify that required labels exist in the repository.

        Checks for:
        - bot_label: Label applied to all bot-created PRs and issues
        - split_label: Label applied to split PRs

        Raises RuntimeError if any required labels are missing.
        """
        bot_label = self.config.get("bot_label")
        split_label = self.config.get("split_label")

        self.logger.debug(
            f"Checking for required labels: bot_label='{bot_label}', split_label='{split_label}'"
        )

        try:
            # Get all labels from the repository
            output = run(["gh", "label", "list", "--json", "name"])
            labels_data = json.loads(output)
            existing_labels = {label["name"] for label in labels_data}

            self.logger.debug(
                f"Found {len(existing_labels)} labels in repository"
            )

            # Check which required labels are missing
            missing_labels = []
            if bot_label not in existing_labels:
                missing_labels.append(bot_label)
            if split_label not in existing_labels:
                missing_labels.append(split_label)

            if missing_labels:
                labels_str = "', '".join(missing_labels)
                raise RuntimeError(
                    f"Required labels missing in repository: '{labels_str}'. "
                    f"Please create them using: gh label create <label-name>"
                )

            self.logger.info(
                f"Verified required labels exist: '{bot_label}', '{split_label}'"
            )

        except json.JSONDecodeError as e:
            self.logger.warning(
                f"Could not parse label list output: {e}. Skipping label check."
            )
        except RuntimeError:
            # Re-raise label missing errors
            raise
        except Exception as e:
            self.logger.warning(
                f"Could not verify labels exist (gh cli may not be available): {e}. "
                f"Skipping label check."
            )

    def _determine_upstream_from_pr(self, pr: Dict) -> Optional[Dict]:
        """
        Determine which upstream a PR belongs to by examining its branch name
        and PR body.

        Args:
            pr: PR dict with keys: headRefName, body

        Returns:
            Upstream config dict or None if cannot determine
        """
        branch = pr.get("headRefName", "")
        body = pr.get("body", "")

        # Try to match branch name pattern: {pr_branch_prefix}/{prefix}/update
        for prefix, upstream_config in self.upstreams.items():
            if f"{self.pr_branch_prefix}/{prefix}" in branch:
                self.logger.debug(
                    f"Matched upstream {prefix} from branch name: {branch}"
                )
                return upstream_config

        # Try to match trailer key in PR body
        for prefix, upstream_config in self.upstreams.items():
            trailer_key = upstream_config["trailer_key"]
            if trailer_key in body:
                self.logger.debug(
                    f"Matched upstream {prefix} from trailer key: {trailer_key}"
                )
                return upstream_config

        # Default to primary upstream if no match
        primary = next(
            (u for u in self.upstreams.values() if u.get("is_primary")), None
        )
        if primary:
            self.logger.warning(
                f"Could not determine upstream from PR, defaulting to primary: {primary['prefix']}"
            )
        return primary

    def _get_upstream_for_cookbook(self, cookbook: str) -> Optional[Dict]:
        """
        Determine which upstream a cookbook belongs to based on its prefix.

        Args:
            cookbook: Cookbook name (e.g., "fb_apache", "pd_something")

        Returns:
            Upstream config dict or None if no match
        """
        for prefix, upstream_config in self.upstreams.items():
            if cookbook.startswith(prefix):
                return upstream_config
        return None

    def _get_upstream_for_commit(self, commit: str) -> Optional[Dict]:
        """
        Determine which upstream a commit belongs to by checking which cookbooks it touches.

        Args:
            commit: Commit SHA

        Returns:
            Upstream config dict or None if no match
        """
        files = git(
            "show", "--name-only", "--pretty=format:", commit
        ).splitlines()
        cookbooks_touched = {
            f.split("/")[1]
            for f in files
            if f.startswith("cookbooks/") and "/" in f
        }

        # Check which upstream these cookbooks belong to
        for cookbook in cookbooks_touched:
            upstream_config = self._get_upstream_for_cookbook(cookbook)
            if upstream_config:
                return upstream_config

        return None

    def _extract_upstream_commits(
        self,
        branch: str,
        max_count: Optional[int] = None,
        return_all: bool = False,
        trailer_key: str = "Upstream-Commit",
    ) -> Optional[List[str]]:
        """
        Helper to extract upstream commit trailer values from git log.

        Args:
            branch: Branch to search
            max_count: Limit number of commits to search (None = all)
            return_all: If True, return all commits; if False, return first
            trailer_key: Trailer key to search for (e.g., "Upstream-Commit", "pd_Upstream-Commit")

        Returns:
            List of commit SHAs (or None if none found and return_all=False)
        """
        cmd = [
            "log",
            branch,
            f"--grep={trailer_key}:",
            "--pretty=format:%B",
        ]
        if max_count:
            cmd.extend(["-n", str(max_count)])

        log = git(*cmd)
        matches = re.findall(
            rf"{re.escape(trailer_key)}:\s*([0-9a-f]{{40}})", log
        )

        if return_all:
            return matches
        return matches[0] if matches else None

    def fetch_upstream(self, upstream_config: Optional[Dict] = None) -> None:
        """
        Fetch the latest commits from upstream remote(s).

        Args:
            upstream_config: If provided, fetch only this upstream.
                            If None, fetch all upstreams.
        """
        if upstream_config:
            # Fetch specific upstream
            remote = upstream_config["remote"]
            self.logger.info(f"Fetching upstream from remote: {remote}")
            git("fetch", remote)
            self.logger.debug("Upstream fetch completed")
        else:
            # Fetch all upstreams
            self.logger.info("Fetching all upstreams")
            for prefix, config in self.upstreams.items():
                remote = config["remote"]
                self.logger.info(
                    f"Fetching {prefix} upstream from remote: {remote}"
                )
                git("fetch", remote)
            self.logger.debug("All upstream fetches completed")

    def upstream_commits_since(
        self, pointer: Optional[str], upstream_config: Dict
    ) -> List[str]:
        """
        Get list of upstream commits since the given pointer (exclusive).

        Args:
            pointer: Starting commit SHA (exclusive)
            upstream_config: Upstream configuration dict

        Returns:
            List of commit SHAs
        """
        if not pointer:
            self.logger.debug(
                "No pointer provided, returning empty commit list"
            )
            return []

        remote = upstream_config["remote"]
        branch = upstream_config["branch"]

        self.logger.debug(
            f"Getting upstream commits since: {pointer} from {remote}/{branch}"
        )
        commits = git(
            "rev-list",
            "--reverse",
            f"{pointer}..{remote}/{branch}",
        ).splitlines()
        self.logger.debug(f"Found {len(commits)} upstream commits")
        return commits

    def existing_sync_pr(self, upstream_config: Dict) -> Optional[Dict]:
        """
        Check for an existing open sync PR created by the bot for a specific
        upstream (based on branch name pattern and labels).

        Args:
            upstream_config: Upstream configuration dict

        Returns:
            PR dict or None
        """
        prefix = upstream_config["prefix"]
        # Branch pattern: {pr_branch_prefix}/{prefix}/update
        branch_prefix = f"{self.pr_branch_prefix}/{prefix}"

        self.logger.debug(
            f"Searching for existing sync PR for {prefix} on branch: {self.base_branch}"
        )
        output = run(
            [
                "gh",
                "pr",
                "list",
                "--base",
                self.base_branch,
                "--state",
                "open",
                "--json",
                "number,headRefName,labels",
            ]
        )
        prs = json.loads(output)
        self.logger.debug(f"Found {len(prs)} open PRs")
        split_label = self.config.get("split_label")
        for pr in prs:
            if pr["headRefName"].startswith(branch_prefix):
                # Skip PRs that have been split
                pr_label_names = [
                    label["name"] for label in pr.get("labels", [])
                ]
                if split_label in pr_label_names:
                    self.logger.debug(
                        f"Skipping split PR #{pr['number']} ({pr['headRefName']})"
                    )
                    continue
                self.logger.debug(
                    f"Found existing sync PR for {prefix}: #{pr['number']} ({pr['headRefName']})"
                )
                return pr
        self.logger.debug(f"No existing sync PR found for {prefix}")
        return None

    def get_branch_trailers(
        self, branch: str, trailer_key: str = "Upstream-Commit"
    ) -> List[str]:
        """
        Get all upstream commit trailer values from a branch.

        Args:
            branch: Branch name
            trailer_key: Trailer key to search for (e.g., "Upstream-Commit", "pd_Upstream-Commit")

        Returns:
            List of all upstream commit SHAs found in branch history.
        """
        self.logger.debug(
            f"Getting branch trailers for: {branch} with key: {trailer_key}"
        )
        trailers = self._extract_upstream_commits(
            branch, max_count=None, return_all=True, trailer_key=trailer_key
        )
        self.logger.debug(f"Found {len(trailers)} trailers")
        return trailers

    def get_branch_commits_with_trailers(
        self, branch: str, trailer_key: str = "Upstream-Commit"
    ) -> List[Tuple[str, str]]:
        """
        Get branch commits that have upstream commit trailers, returned as list
        of (branch_commit_hash, upstream_commit_hash) tuples in chronological
        order.

        Args:
            branch: Branch name
            trailer_key: Trailer key to search for (e.g., "Upstream-Commit", "pd_Upstream-Commit")

        Returns:
            List of (branch_commit, upstream_commit) tuples
        """
        self.logger.debug(
            f"Getting branch commits with trailers for: {branch} with key: {trailer_key}"
        )
        # Get all commits in branch with trailers (not just ones not in
        # self.base_branch). This is important because user might be splitting a
        # partially-merged PR
        log = git(
            "log",
            branch,
            f"--grep={trailer_key}:",
            "--pretty=format:%H|%B%n---COMMIT-SEPARATOR---",
            "--reverse",
        )

        commits = []
        for entry in log.split("---COMMIT-SEPARATOR---"):
            entry = entry.strip()
            if not entry:
                continue

            lines = entry.split("|", 1)
            if len(lines) < 2:
                continue

            branch_commit = lines[0].strip()
            message = lines[1]

            # Extract upstream commit from trailer
            match = re.search(
                rf"{re.escape(trailer_key)}:\s*([0-9a-f]{{40}})", message
            )
            if match:
                upstream_commit = match.group(1)
                commits.append((branch_commit, upstream_commit))
                self.logger.debug(
                    f"  Found: branch={branch_commit[:8]} -> upstream={upstream_commit[:8]}"
                )

        self.logger.debug(f"Found {len(commits)} branch commits with trailers")
        return commits

    def shortlog(self, commit: str) -> str:
        """Get a one-line summary of a commit for PR description."""
        return git("log", "-1", "--pretty=%s", commit)

    def pr_title_and_description_from_commits(
        self, commits: List[str], trailer_key: str = "Upstream-Commit"
    ) -> Tuple[str, str]:
        """
        Build a PR title and description from a list of upstream commits.

        Args:
            commits: List of upstream commit SHAs
            trailer_key: Trailer key to use in commit entries

        Returns:
            Tuple of (title, body)
        """
        commit_entries = []
        for c in commits:
            commit_entries.append(
                f"* {self.shortlog(c)}\n  * {trailer_key}: {c}\n"
            )

        prefix = self.config.get("bot_command_prefix")
        cmds = [
            f"{prefix} split <shaA>-<shaB>: Split range of commits into a separate PR. Must be first or last commits.",
            f"{prefix} rebase: Rebase this PR",
        ]

        body = "Syncing upstream commits. The PRs are listed below. You can"
        body += " comment in this PR with commands see below. Also, this"
        body += " description is build for squash-merge, make sure you keep"
        body += f" all the `{trailer_key}` trailers in tact.\n\n"
        body += "\n".join(commit_entries)
        body += "\n\nCommands:\n```\t" + "\n\t".join(cmds) + "\n```\n"

        title = f"Sync upstream ({len(commits)} commits)"

        return (title, body)

    def _build_gh_pr_command(
        self, action: str, title: str, body: str, **kwargs
    ) -> List[str]:
        """
        Build a gh pr command with common options.

        Args:
            action: "create" or "edit"
            title: PR title
            body: PR body
            **kwargs: Additional options (pr_number, branch, base, etc.)

        Returns:
            Command list ready for run()
        """
        cmd = ["gh", "pr", action]

        if action == "edit":
            cmd.append(str(kwargs["pr_number"]))
            cmd.extend(["--title", title])
            # Add label for edit
            bot_label = self.config.get("bot_label")
            cmd.extend(["--add-label", bot_label])
        elif action == "create":
            cmd.extend(["--title", title])
            if "branch" in kwargs:
                cmd.extend(["--head", kwargs["branch"]])
            if "base" in kwargs:
                cmd.extend(["--base", kwargs["base"]])
            # Add label for create
            bot_label = self.config.get("bot_label")
            cmd.extend(["--label", bot_label])

        cmd.extend(["--body", body])
        return cmd

    def _build_gh_issue_command(self, action: str, **kwargs) -> List[str]:
        """
        Build a gh issue command with common options.

        Args:
            action: "create", "edit", "list", "close", or "comment"
            **kwargs: Additional options depending on action:
                - For "create": title, body
                - For "edit": issue_number, body, title (optional)
                - For "list": state, json_fields, search
                - For "close": issue_number
                - For "comment": issue_number, body

        Returns:
            Command list ready for run()
        """
        cmd = ["gh", "issue", action]

        if action == "list":
            if "state" in kwargs:
                cmd.extend(["--state", kwargs["state"]])
            if "json_fields" in kwargs:
                cmd.extend(["--json", kwargs["json_fields"]])
            if "search" in kwargs:
                cmd.extend(["--search", kwargs["search"]])
        elif action == "create":
            cmd.extend(["--title", kwargs["title"]])
            cmd.extend(["--body", kwargs["body"]])
            # Add label from config
            bot_label = self.config.get("bot_label")
            cmd.extend(["--label", bot_label])
        elif action == "edit":
            cmd.append(str(kwargs["issue_number"]))
            if "title" in kwargs:
                cmd.extend(["--title", kwargs["title"]])
            cmd.extend(["--body", kwargs["body"]])
        elif action == "close":
            cmd.append(str(kwargs["issue_number"]))
        elif action == "comment":
            cmd.extend(["comment", str(kwargs["issue_number"])])
            cmd.extend(["--body", kwargs["body"]])

        return cmd

    def add_comment(
        self, pr_number: int, body: str, is_issue: bool = False
    ) -> None:
        """
        Add a comment to a PR or Issue.

        Args:
            pr_number: PR or Issue number
            body: Comment body text
            is_issue: If True, comment on an issue; if False, comment on a PR
        """
        entity_type = "issue" if is_issue else "PR"
        self.logger.debug(f"Adding comment to {entity_type} #{pr_number}")

        if not self.dry_run:
            self.logger.info(f"Adding comment to {entity_type} #{pr_number}")
            cmd = [
                "gh",
                "pr" if not is_issue else "issue",
                "comment",
                str(pr_number),
                "--body",
                body,
            ]
            run(cmd)
        else:
            self.logger.info(
                f"[dry-run] Would add comment to {entity_type} #{pr_number}: {body[:50]}..."
            )

    def update_pr_body(
        self,
        pr_number: int,
        commits: List[str],
        trailer_key: str = "Upstream-Commit",
    ) -> None:
        """
        Update an existing PR's title and body with new commit list.

        Args:
            pr_number: PR number
            commits: List of upstream commit SHAs
            trailer_key: Trailer key to use in commit entries
        """
        self.logger.debug(
            f"Updating PR #{pr_number} with {len(commits)} commits"
        )
        (title, body) = self.pr_title_and_description_from_commits(
            commits, trailer_key
        )
        if not self.dry_run:
            self.logger.info(f"Updating PR #{pr_number} title and body")
            cmd = self._build_gh_pr_command(
                "edit", title, body, pr_number=pr_number
            )
            run(cmd)
        else:
            self.logger.info(
                f"[dry-run] Would update PR #{pr_number} title and body with {len(commits)} commits"
            )

    def find_existing_issue_for_cookbook(self, cookbook: str) -> Optional[int]:
        """
        Find an existing open issue for a cookbook's local changes.
        Returns the issue number if found, None otherwise.
        """
        self.logger.debug(
            f"Searching for existing issue for cookbook: {cookbook}"
        )
        try:
            cmd = self._build_gh_issue_command(
                "list",
                state="open",
                json_fields="number,title",
                search=f"Local changes detected in {cookbook} in:title",
            )
            output = run(cmd)
            issues = json.loads(output)
            self.logger.debug(f"Found {len(issues)} potential matching issues")
            for issue in issues:
                # Check if the issue title contains this specific cookbook
                if cookbook in issue["title"]:
                    self.logger.debug(
                        f"Found existing issue #{issue['number']} for {cookbook}"
                    )
                    return issue["number"]
        except RuntimeError as e:
            self.logger.warning(f"Error searching for existing issue: {e}")
            pass
        self.logger.debug(f"No existing issue found for {cookbook}")
        return None

    def create_conflict_issue(
        self,
        commit: str,
        cookbooks: Optional[List[str]] = None,
        conflict_details: Optional[str] = None,
        dry_run: bool = False,
    ) -> None:
        """
        Create or update a GitHub issue for a sync conflict (single issue
        regardless of cookbooks involved).
        - commit: upstream commit SHA that caused the conflict
        - cookbooks: list of cookbook names involved (optional, for context)
        - conflict_details: optional string with conflict details to include in
          the issue
        - dry_run: if True, just log what would happen
        """
        self.logger.debug(
            f"Creating/updating conflict issue for commit {commit[:8]}, cookbooks: {cookbooks}"
        )
        if conflict_details:
            self.logger.debug(
                f"Conflict details provided: {len(conflict_details)} chars"
            )

        title = f"Sync conflict applying upstream commit {commit[:8]}"

        body_lines = [
            f"**A conflict occurred** while applying upstream commit `{commit}`.",
            "\nThe changes are blocking the sync and must be resolved before continuing.",
        ]

        if cookbooks:
            body_lines.append(
                f"\n**Cookbooks involved:** {', '.join(cookbooks)}"
            )

        if conflict_details:
            body_lines.append(
                "\n## Conflict Details\n\n```\n" + conflict_details + "\n```"
            )

        body_lines.append(
            "\n**Action required:** Please resolve the conflicts and push the changes."
        )

        body = "\n".join(body_lines)

        # Check for existing conflict issue for this commit
        existing_issue = None
        try:
            self.logger.debug(
                f"Searching for existing conflict issue for commit {commit[:8]}"
            )
            cmd = self._build_gh_issue_command(
                "list",
                state="open",
                json_fields="number,title",
                search=f"Sync conflict applying upstream commit {commit[:8]} in:title",
            )
            output = run(cmd)
            issues = json.loads(output)
            self.logger.debug(f"Found {len(issues)} potential matching issues")
            for issue in issues:
                # Check if the issue title matches this specific commit
                if commit[:8] in issue["title"]:
                    self.logger.debug(
                        f"Found existing conflict issue #{issue['number']} for commit {commit[:8]}"
                    )
                    existing_issue = issue["number"]
                    break
        except RuntimeError as e:
            self.logger.warning(
                f"Error searching for existing conflict issue: {e}"
            )

        # Close any older conflict issues since this commit is now the blocker
        # Do this before the dry_run check so it happens in both modes
        self.logger.debug(
            f"Checking for older conflict issues to close (current blocker: {commit[:8]})"
        )
        self.close_resolved_conflict_issues(commit, dry_run=dry_run)

        if dry_run:
            if existing_issue:
                self.logger.info(
                    f"[dry-run] Would update conflict issue #{existing_issue}"
                )
            else:
                self.logger.info(
                    f"[dry-run] Would create conflict issue: {title}"
                )
            return

        try:
            if existing_issue:
                self.logger.info(
                    f"Updating existing conflict issue #{existing_issue} for commit {commit[:8]}"
                )
                cmd = self._build_gh_issue_command(
                    "edit", issue_number=existing_issue, body=body
                )
                run(cmd)
                self.logger.info(
                    f"Conflict issue #{existing_issue} updated for commit {commit[:8]}"
                )
            else:
                self.logger.info(
                    f"Creating conflict issue for commit {commit[:8]}"
                )
                cmd = self._build_gh_issue_command(
                    "create", title=title, body=body
                )
                run(cmd)
                self.logger.info(
                    f"Conflict issue created for commit {commit[:8]}"
                )

        except RuntimeError as e:
            self.logger.error(f"Failed to create/update conflict issue: {e}")

    def close_resolved_conflict_issues(
        self, current_pointer: str, dry_run: bool = False
    ) -> None:
        """
        Close any open conflict issues for commits that have been successfully
        synced past.
        - current_pointer: the current upstream commit pointer (commits before
          this are resolved)
        - dry_run: if True, just log what would happen
        """
        self.logger.debug(
            f"Checking for old conflict issues to close (current pointer: {current_pointer[:8]})"
        )

        try:
            # Search for all open conflict issues
            cmd = self._build_gh_issue_command(
                "list",
                state="open",
                json_fields="number,title",
                search="Sync conflict applying upstream commit in:title",
            )
            output = run(cmd)
            issues = json.loads(output)
            self.logger.debug(f"Found {len(issues)} open conflict issues")

            for issue in issues:
                # Extract commit hash from title: "Sync conflict applying upstream commit <hash>"
                title = issue["title"]
                match = re.search(
                    r"Sync conflict applying upstream commit ([0-9a-f]{8})",
                    title,
                )
                if not match:
                    self.logger.debug(
                        f"Issue #{issue['number']} title doesn't match expected format: {title}"
                    )
                    continue

                issue_commit = match.group(1)
                self.logger.debug(
                    f"Checking issue #{issue['number']} for commit {issue_commit}"
                )

                # Find the full commit hash from the short hash
                try:
                    full_hash = git("rev-parse", "--verify", issue_commit)
                    self.logger.debug(
                        f"Resolved {issue_commit} to full hash {full_hash[:8]}..."
                    )
                except RuntimeError:
                    self.logger.warning(
                        f"Could not resolve commit hash {issue_commit} from issue #{issue['number']}"
                    )
                    continue

                # Check if this commit has been synced (is it an ancestor of current_pointer, but not current_pointer itself)
                is_ancestor, _, _ = try_git(
                    "merge-base", "--is-ancestor", full_hash, current_pointer
                )
                is_same = full_hash == current_pointer

                # Only close if it's an ancestor but NOT the current pointer (which is the active blocker)
                if is_ancestor and not is_same:
                    self.logger.info(
                        f"Conflict issue #{issue['number']} for commit {issue_commit} is now resolved"
                    )

                    if dry_run:
                        self.logger.info(
                            f"[dry-run] Would close issue #{issue['number']}"
                        )
                    else:
                        try:
                            comment = f"This conflict has been resolved. The sync has successfully moved past commit {issue_commit}."
                            cmd_comment = self._build_gh_issue_command(
                                "comment",
                                issue_number=issue["number"],
                                body=comment,
                            )
                            run(cmd_comment)
                            cmd_close = self._build_gh_issue_command(
                                "close", issue_number=issue["number"]
                            )
                            run(cmd_close)
                            self.logger.info(
                                f"Closed resolved conflict issue #{issue['number']}"
                            )
                        except RuntimeError as e:
                            self.logger.error(
                                f"Failed to close issue #{issue['number']}: {e}"
                            )
                else:
                    self.logger.debug(
                        f"Conflict issue #{issue['number']} for commit {issue_commit} is still blocking"
                    )

        except RuntimeError as e:
            self.logger.warning(
                f"Error searching for conflict issues to close: {e}"
            )

    def create_or_update_issue_for_local_changes(
        self,
        cookbooks: List[str],
        commit: str,
        dry_run: bool = False,
    ) -> None:
        """
        Create or update GitHub issues noting that local changes exist in
        cookbooks.

        Creates/updates one issue per cookbook (for non-blocking local changes
        after successful sync).
        - cookbooks: list of cookbook names
        - commit: upstream commit SHA of last successful sync
        - dry_run: if True, just log what would happen
        """
        self.logger.debug(
            f"Processing {len(cookbooks)} cookbooks with local changes"
        )

        for cookbook in cookbooks:
            self.logger.debug(
                f"Creating/updating issue for cookbook: {cookbook}"
            )
            title = f"Local changes detected in {cookbook}"
            body_lines = [
                f"The cookbook `{cookbook}` has local changes.",
                f"\n**ℹ️ These changes have not caused conflicts** (last sync: {commit[:8]}).",
                "\nHowever, they should be pushed upstream to avoid future conflicts.",
                "\n**Action required:** Please push these changes upstream.",
            ]

            body = "\n".join(body_lines)

            # Check for existing issue
            existing_issue = self.find_existing_issue_for_cookbook(cookbook)

            if dry_run:
                if existing_issue:
                    self.logger.info(
                        f"[dry-run] Would update issue #{existing_issue}"
                    )
                else:
                    self.logger.info(f"[dry-run] Would create issue: {title}")
                continue

            # Update or create the issue via GitHub CLI
            try:
                if existing_issue:
                    self.logger.debug(
                        f"Updating issue #{existing_issue} for {cookbook}"
                    )
                    cmd = self._build_gh_issue_command(
                        "edit", issue_number=existing_issue, body=body
                    )
                    run(cmd)
                    self.logger.info(
                        f"Issue #{existing_issue} updated for {cookbook}"
                    )
                else:
                    self.logger.debug(f"Creating new issue for {cookbook}")
                    cmd = self._build_gh_issue_command(
                        "create", title=title, body=body
                    )
                    run(cmd)
                    self.logger.info(
                        f"Issue created for local changes in {cookbook}"
                    )
            except RuntimeError as e:
                self.logger.error(
                    f"Failed to create/update issue for {cookbook}: {e}"
                )

    def create_pr(
        self,
        branch: str,
        commits: List[str],
        trailer_key: str = "Upstream-Commit",
    ) -> Optional[int]:
        """
        Create a new PR for syncing upstream commits.

        Args:
            branch: Branch name
            commits: List of upstream commit SHAs
            trailer_key: Trailer key to use in commit entries

        Returns:
            PR number or None if dry-run
        """
        self.logger.debug(
            f"Creating PR for branch {branch} with {len(commits)} commits"
        )
        (title, body) = self.pr_title_and_description_from_commits(
            commits, trailer_key
        )
        if not self.dry_run:
            cmd = self._build_gh_pr_command(
                "create", title, body, branch=branch, base=self.base_branch
            )
            pr_url = run(cmd)
            # Extract PR number from URL
            pr_number = int(pr_url.strip().split("/")[-1])
            self.logger.debug(f"Created PR #{pr_number}: {pr_url}")
            return pr_number
        else:
            self.logger.info(
                f"[dry-run] Would create PR {branch} with {len(commits)} commits"
            )
            return None

    def create_onboarding_pr(
        self, baseline: str, trailer_key: str = "Upstream-Commit"
    ) -> Optional[int]:
        """
        Create onboarding PR to establish initial upstream sync baseline.

        Args:
            baseline: Baseline commit SHA
            trailer_key: Trailer key to use

        Returns:
            PR number or None if dry-run
        """
        self.logger.info(f"Creating onboarding PR with baseline: {baseline}")
        branch = f"{self.pr_branch_prefix}/onboard"
        self.logger.debug(f"Checking out branch: {branch}")
        git("checkout", "-B", branch, self.base_branch)

        msg = f"""Initialize upstream sync baseline

This establishes the initial upstream pointer.

{trailer_key}: {baseline}
"""
        self.logger.debug("Creating empty commit with baseline")
        git("commit", "--allow-empty", "-m", msg)

        if not self.dry_run:
            git("push", "-f", self.target_remote, branch)

            # Actually create the PR
            title = "Initialize upstream sync baseline"
            body = f"""This PR establishes the initial upstream pointer for automated syncing.

Upstream baseline: `{baseline}`

Merge this PR to enable automated upstream syncing.
"""
            cmd = self._build_gh_pr_command(
                "create", title, body, branch=branch, base=self.base_branch
            )
            pr_url = run(cmd)
            pr_number = int(pr_url.strip().split("/")[-1])
            self.logger.info(f"Onboarding PR #{pr_number} created: {pr_url}")
            return pr_number
        else:
            self.logger.debug(f"[dry-run] Created onboarding branch {branch}")
            return None

    def is_commit_already_applied(
        self, commit: str, upstream_config: Dict
    ) -> bool:
        """
        Check if the changes from a commit are already present in the current
        branch. This checks the actual content, not just the upstream commit
        trailer. Returns True if all relevant cookbook changes from the commit
        are already present.

        Args:
            commit: Upstream commit SHA
            upstream_config: Upstream configuration dict

        Returns:
            True if commit changes are already applied
        """
        self.logger.debug(
            f">>> self.is_commit_already_applied() ENTRY for {commit[:8]}"
        )

        try:
            local_cookbooks = set(self.list_local_cookbooks(upstream_config))
            self.logger.debug(f"Got {len(local_cookbooks)} local cookbooks")
        except Exception as e:
            self.logger.error(f"Failed to get local cookbooks: {e}")
            return False

        prefix = upstream_config["prefix"]
        ignore_cookbooks = upstream_config.get("ignore_cookbooks", [])

        # Get the diff for this commit, filtered to cookbooks with matching prefix that we have locally
        try:
            # Get list of files changed in the commit that are in our local cookbooks
            files_in_commit = git(
                "show", "--name-only", "--pretty=format:", commit
            ).splitlines()
            relevant_files = []
            for file_path in files_in_commit:
                if file_path.startswith(f"cookbooks/{prefix}"):
                    parts = file_path.split("/")
                    if len(parts) >= 2:
                        cookbook = parts[1]
                        if (
                            cookbook in local_cookbooks
                            and cookbook not in ignore_cookbooks
                        ):
                            relevant_files.append(file_path)

            if not relevant_files:
                self.logger.debug(
                    f"No relevant {prefix} files in commit {commit[:8]}"
                )
                return True  # No relevant changes, consider it "applied"

            self.logger.debug(
                f"Checking {len(relevant_files)} relevant files from {commit[:8]}"
            )

            # For each relevant file, check if the content matches
            # by comparing the file at commit with the file at HEAD
            all_match = True
            for file_path in relevant_files:
                # Get the file content at the commit
                success_commit, content_at_commit, _ = try_git(
                    "show", f"{commit}:{file_path}"
                )
                # Get the file content at HEAD
                success_head, content_at_head, _ = try_git(
                    "show", f"HEAD:{file_path}"
                )

                if success_commit and success_head:
                    if content_at_commit != content_at_head:
                        self.logger.debug(
                            f"File {file_path} differs between HEAD and {commit[:8]}"
                        )
                        all_match = False
                        break
                elif success_commit and not success_head:
                    # File exists in commit but not in HEAD - changes not applied
                    self.logger.debug(
                        f"File {file_path} exists in {commit[:8]} but not in HEAD"
                    )
                    all_match = False
                    break
                elif not success_commit and success_head:
                    # File deleted in commit but exists in HEAD - changes not applied
                    self.logger.debug(
                        f"File {file_path} should be deleted per {commit[:8]} but exists in HEAD"
                    )
                    all_match = False
                    break
                # If both don't exist, that's fine - continue checking

            if all_match:
                self.logger.info(
                    f"All changes from {commit[:8]} are already present"
                )
                return True
            else:
                self.logger.debug(
                    f"Changes from {commit[:8]} are not fully present"
                )
                return False

        except RuntimeError as e:
            self.logger.warning(
                f"Error checking if commit already applied: {e}"
            )
            return False

    def capture_conflict_details(self, conflicting_files: List[str]) -> str:
        """
        Capture the conflict details for files that have conflicts.
        Returns a formatted string showing the conflicts.
        """
        self.logger.debug(
            f"self.capture_conflict_details() called with {len(conflicting_files)} files: {conflicting_files}"
        )
        details_lines = []

        for file_path in conflicting_files[
            :10
        ]:  # Limit to first 10 files to avoid huge issues
            self.logger.debug(f"Processing conflict file: {file_path}")
            details_lines.append(f"### {file_path}")
            details_lines.append("")

            # Try to read the conflicting file to show conflict markers
            try:
                with open(file_path, "r") as f:
                    content = f.read()
                    self.logger.debug(
                        f"Read {len(content)} chars from {file_path}"
                    )
                    # Only include up to first 100 lines or 5000 chars to keep issue manageable
                    lines = content.splitlines()
                    if len(lines) > 100:
                        content = "\n".join(lines[:100]) + "\n... (truncated)"
                    elif len(content) > 5000:
                        content = content[:5000] + "\n... (truncated)"
                    details_lines.append(content)
            except Exception as e:
                self.logger.warning(f"Could not read {file_path}: {e}")
                details_lines.append(f"(Could not read file: {e})")

            details_lines.append("")

        if len(conflicting_files) > 10:
            details_lines.append(
                f"... and {len(conflicting_files) - 10} more conflicting files"
            )

        result = "\n".join(details_lines)
        self.logger.debug(
            f"self.capture_conflict_details() returning {len(result)} chars"
        )
        return result

    def _abort_cherry_pick_safely(self) -> None:
        """
        Safely abort a cherry-pick with fallback to manual cleanup.
        """
        try:
            git("cherry-pick", "--abort")
            self.logger.debug("Cherry-pick aborted successfully")
        except RuntimeError as e:
            self.logger.warning(f"Cherry-pick abort failed forcing cleanup")
            git("reset", "--hard", "HEAD")
            git("clean", "-fd")
            self.logger.debug("Forced cleanup completed")

    def _get_conflicting_files(self) -> List[str]:
        """
        Get list of conflicting files from git status.

        Returns:
            List of file paths with conflicts
        """
        status_output = git("status", "--porcelain")
        self.logger.debug(
            f"Status output: {len(status_output)} chars, "
            f"{len(status_output.splitlines())} lines"
        )

        conflicting_files = []
        conflict_markers = ("DU ", "UD ", "DD ", "AA ", "UU ")

        for line in status_output.splitlines():
            if len(line) > 2 and line.startswith(conflict_markers):
                file_path = line[2:].lstrip()
                conflicting_files.append(file_path)
                self.logger.debug(
                    f"Found conflict marker: {line[:2]} for: {file_path}"
                )

        self.logger.debug(f"Total conflicting files: {conflicting_files}")
        return conflicting_files

    def _categorize_conflicts(
        self, conflicting_files: List[str], upstream_config: Dict
    ) -> Tuple[List[str], List[str]]:
        """
        Categorize conflicts into real vs auto-resolvable.

        Real conflicts: files in local cookbooks with matching prefix
        Auto-resolve: non-existent cookbooks or non-matching prefix files

        Args:
            conflicting_files: List of file paths with conflicts
            upstream_config: Upstream configuration dict

        Returns:
            Tuple of (real_conflicts, auto_resolve_conflicts)
        """
        prefix = upstream_config["prefix"]
        local_cookbooks = set(self.list_local_cookbooks(upstream_config))
        self.logger.debug(
            f"Local cookbooks for conflict check ({prefix}): {local_cookbooks}"
        )

        auto_resolve_conflicts = []
        real_conflicts = []

        for file_path in conflicting_files:
            if file_path.startswith(f"cookbooks/{prefix}"):
                parts = file_path.split("/")
                if len(parts) >= 2:
                    cookbook = parts[1]
                    if (
                        cookbook.startswith(prefix)
                        and cookbook in local_cookbooks
                    ):
                        self.logger.debug(
                            f"Real conflict: {file_path} "
                            f"(cookbook {cookbook} is local)"
                        )
                        real_conflicts.append(file_path)
                    else:
                        self.logger.debug(
                            f"Auto-resolve: {file_path} "
                            f"(cookbook {cookbook} not local)"
                        )
                        auto_resolve_conflicts.append(file_path)
                else:
                    auto_resolve_conflicts.append(file_path)
            else:
                # Not a matching prefix cookbook file - auto-resolve
                auto_resolve_conflicts.append(file_path)

        self.logger.debug(
            f"Categorization: {len(real_conflicts)} real, "
            f"{len(auto_resolve_conflicts)} auto-resolve"
        )
        return real_conflicts, auto_resolve_conflicts

    def _capture_basic_conflict_info(self) -> str:
        """
        Capture basic conflict info for error reporting.

        Returns:
            String with conflict details or error message
        """
        try:
            self.logger.debug("Capturing basic conflict info...")
            conflicting_files = self._get_conflicting_files()

            if not conflicting_files:
                return "No conflict details available"

            conflict_info = self.capture_conflict_details(conflicting_files)
            self.logger.debug(
                f"Basic conflict info captured: {len(conflict_info)} chars"
            )
            return conflict_info
        except Exception as e:
            self.logger.warning(f"Error capturing basic conflict info: {e}")
            return "Could not capture conflict details"

    def cherry_pick_with_trailer(
        self, commit: str, upstream_config: Dict
    ) -> bool:
        """
        Cherry-pick a commit with an upstream commit trailer.
        Returns True if the commit was applied, False if it was skipped.
        Raises RuntimeError on conflicts.

        Args:
            commit: Upstream commit SHA
            upstream_config: Upstream configuration dict

        Returns:
            True if commit was applied, False if skipped
        """
        self.logger.debug(
            f"=== self.cherry_pick_with_trailer() ENTRY for commit: {commit}"
        )

        # Check if this commit has already been applied (optimization)
        self.logger.debug(
            "Checking if commit already applied (pre-cherry-pick)"
        )
        if self.is_commit_already_applied(commit, upstream_config):
            self.logger.info(f"Commit {commit[:8]} already applied, skipping")
            return False

        self.logger.debug(
            f"Commit {commit[:8]} not already applied, proceeding with cherry-pick"
        )
        self.logger.info(f"Applying {commit}")

        # Use --no-commit so we can filter what gets applied
        # Disable rename detection to avoid false conflicts between local-only
        # and upstream-only cookbooks
        self.logger.debug(
            "About to call try_git for cherry-pick --no-commit -X no-renames"
        )
        success, _, stderr = try_git(
            "cherry-pick", "--no-commit", "-X", "no-renames", commit
        )
        self.logger.debug(f"try_git returned: success={success}")

        if not success:
            self.logger.warning(f"Conflict during cherry-pick of {commit}")
            self.logger.debug(f"Cherry-pick stderr: {stderr[:200]}")

            # Check if already applied despite conflict
            try:
                if self.is_commit_already_applied(commit, upstream_config):
                    self.logger.info(
                        f"Commit {commit[:8]} already applied, skipping"
                    )
                    self._abort_cherry_pick_safely()
                    return False
            except Exception as e:
                self.logger.warning(
                    f"Error checking if commit already applied: {e}"
                )

            # Capture basic conflict info for error reporting
            basic_conflict_info = self._capture_basic_conflict_info()

            # Handle conflicts - categorize and decide action
            try:
                conflicting_files = self._get_conflicting_files()
                real_conflicts, auto_resolve = self._categorize_conflicts(
                    conflicting_files, upstream_config
                )

                if auto_resolve and not real_conflicts:
                    # Only non-relevant conflicts - skip this commit
                    self.logger.info(
                        f"Skipping {commit[:8]} - conflicts only in "
                        "non-matching or non-imported cookbooks"
                    )
                    self._abort_cherry_pick_safely()
                    return False
                else:
                    # Real conflicts in local cookbooks - report error
                    if real_conflicts:
                        self.logger.warning(
                            f"Real conflicts in local cookbooks: "
                            f"{real_conflicts}"
                        )

                    # Capture detailed conflict info
                    all_conflicts = (
                        real_conflicts if real_conflicts else conflicting_files
                    )
                    try:
                        conflict_info = self.capture_conflict_details(
                            all_conflicts
                        )
                    except Exception as e:
                        self.logger.warning(
                            f"Failed to capture conflict details: {e}"
                        )
                        conflict_info = f"Could not capture details: {e}"

                    # Abort cherry-pick and raise error
                    self._abort_cherry_pick_safely()
                    error = RuntimeError(f"Conflict while applying {commit}")
                    error.conflict_details = conflict_info
                    raise error

            except RuntimeError as error:
                # Ensure RuntimeError has conflict_details
                if not hasattr(error, "conflict_details"):
                    error.conflict_details = basic_conflict_info
                raise
            except Exception as e:
                # Wrap unexpected exceptions
                self.logger.error(
                    f"Unexpected error during conflict handling: "
                    f"{type(e).__name__}: {e}"
                )
                self._abort_cherry_pick_safely()
                error = RuntimeError(
                    f"Error while handling conflict in {commit}: {e}"
                )
                error.conflict_details = basic_conflict_info
                raise error
        else:
            # No conflicts, but we still need to filter to only relevant changes
            self.logger.debug(
                f"Cherry-pick successful (no conflicts), filtering to {upstream_config['prefix']} changes only"
            )
            success = self.filter_and_commit_fb_changes(commit, upstream_config)
            if not success:
                self.logger.info(
                    f"No {upstream_config['prefix']} cookbook changes to apply from {commit[:8]}"
                )
                return False  # Successfully skipped - repo already cleaned up
            return True  # Successfully applied

    def filter_and_commit_fb_changes(
        self, commit: str, upstream_config: Dict
    ) -> bool:
        """
        After a cherry-pick --no-commit, filter to only keep changes in
        cookbooks that match the upstream prefix and exist locally, then commit
        with the original message plus trailer. Returns True if changes were
        committed, False if no relevant changes.

        Args:
            commit: Upstream commit SHA
            upstream_config: Upstream configuration dict

        Returns:
            True if changes were committed, False otherwise
        """
        prefix = upstream_config["prefix"]
        trailer_key = upstream_config["trailer_key"]
        ignore_cookbooks = upstream_config.get("ignore_cookbooks", [])

        local_cookbooks = set(self.list_local_cookbooks(upstream_config))

        # Reset the staging area
        git("reset", "HEAD")

        # Get all modified files from the cherry-pick
        status_output = git("status", "--porcelain")
        files_to_add = []

        for line in status_output.splitlines():
            if line.strip():
                # Parse status line (format: "XY filename")
                # The status is 2 chars, followed immediately by the filename
                if len(line) > 2:
                    status_code = line[:2]
                    file_path = line[2:].lstrip()  # Remove any leading spaces
                else:
                    continue  # Malformed line, skip

                self.logger.debug(
                    f"Status line: '{line}' -> status='{status_code}' path='{file_path}'"
                )

                # Only process files in cookbooks with matching prefix that exist locally
                if file_path.startswith(f"cookbooks/{prefix}"):
                    parts = file_path.split("/")
                    if len(parts) >= 2:
                        cookbook = parts[1]
                        if (
                            cookbook.startswith(prefix)
                            and cookbook in local_cookbooks
                            and cookbook not in ignore_cookbooks
                        ):
                            files_to_add.append(file_path)
                            self.logger.debug(
                                f"Including {prefix} file: {file_path}"
                            )
                else:
                    self.logger.debug(
                        f"Ignoring non-{prefix} file: {file_path}"
                    )

        if not files_to_add:
            self.logger.warning(
                f"No {prefix} cookbook files to commit after filtering"
            )
            # Clean up - abort the cherry-pick to clear git state
            self.logger.debug(
                "Aborting cherry-pick and cleaning working directory"
            )
            try:
                # Try to abort cherry-pick if one is in progress
                git("cherry-pick", "--abort")
            except RuntimeError:
                # If no cherry-pick in progress, just clean up manually
                self.logger.debug(
                    "No cherry-pick to abort, doing manual cleanup"
                )
                git("reset", "--hard", "HEAD")
                git("clean", "-fd")
            return False

        # Stage only the relevant cookbook files
        self.logger.debug(
            f"Staging {len(files_to_add)} {prefix} cookbook files"
        )
        for file_path in files_to_add:
            git("add", file_path)

        # Get the original commit message
        message = git("show", "-s", "--format=%B", commit)

        # Add the upstream commit trailer
        if trailer_key not in message:
            message = message.strip() + f"\n\n{trailer_key}: {commit}\n"

        # Commit the filtered changes
        self.logger.debug(
            f"Committing filtered changes with {trailer_key} trailer"
        )
        git("commit", "-m", message)

        return True

    def get_current_pointer(self, upstream_config: Dict) -> Optional[str]:
        """
        Get the most recent upstream commit from target_branch for a given upstream.

        Handles squash-merge case where one commit may have multiple
        upstream commit trailers. Returns the most recent (furthest along
        in upstream history).

        Args:
            upstream_config: Upstream configuration dict.

        Returns:
            SHA of the most recent upstream commit, or None if not found.
        """
        trailer_key = upstream_config["trailer_key"]
        self.logger.debug(
            f"Getting current pointer from {self.base_branch} with trailer: {trailer_key}"
        )

        # Get the most recent commit with upstream commit trailers
        # In case of squash-merge, this one commit will have multiple trailers
        log = git(
            "log",
            self.base_branch,
            f"--grep={trailer_key}:",
            "-n",
            "1",
            "--pretty=format:%B",
        )

        # Find all upstream commit trailers in this commit
        # Strip leading whitespace and bullets to handle nested format like:
        #   * <shortlog>
        #     * Upstream-Commit: <sha>
        trailers = []
        for line in log.splitlines():
            stripped = line.lstrip().lstrip("*").lstrip()
            if stripped.startswith(f"{trailer_key}:"):
                commit = stripped.split(":", 1)[1].strip()
                trailers.append(commit)

        if not trailers:
            self.logger.debug(f"No current pointer found for {trailer_key}")
            return None

        if len(trailers) == 1:
            self.logger.debug(
                f"Current pointer for {trailer_key}: {trailers[0]}"
            )
            return trailers[0]

        # Multiple trailers found (squash-merge case)
        self.logger.debug(
            f"Found {len(trailers)} upstream commit trailers in most recent commit: {[t[:8] for t in trailers]}"
        )

        # Find which trailer is furthest along in upstream history
        most_recent = trailers[0]
        for trailer in trailers[1:]:
            # Check if most_recent is an ancestor of trailer (i.e., trailer is newer)
            is_ancestor, _, _ = try_git(
                "merge-base", "--is-ancestor", most_recent, trailer
            )
            if is_ancestor:
                # trailer is newer/further along, use it instead
                most_recent = trailer
                self.logger.debug(
                    f"Updated pointer to {trailer[:8]} (further along than {most_recent[:8]})"
                )
            else:
                # Check if trailer is an ancestor of most_recent
                is_ancestor, _, _ = try_git(
                    "merge-base", "--is-ancestor", trailer, most_recent
                )
                if not is_ancestor:
                    # They're not related - this might be a problem, but use the first one
                    self.logger.warning(
                        f"Commits {most_recent[:8]} and {trailer[:8]} are not related"
                    )

        self.logger.debug(
            f"Current pointer (most recent in squash-merge) for {trailer_key}: {most_recent}"
        )
        return most_recent

    def list_local_cookbooks(self, upstream_config: Dict) -> List[str]:
        """
        List cookbooks that exist in the current HEAD/branch. Uses git to check
        what's actually committed, not filesystem (which may have conflict
        files). Filters by upstream prefix and ignore_cookbooks config.

        Args:
            upstream_config: Upstream configuration dict.

        Returns:
            List of cookbook names for the specified upstream
        """
        self.logger.debug("Listing local cookbooks from git")

        prefix = upstream_config["prefix"]
        ignore_cookbooks = upstream_config.get("ignore_cookbooks", [])

        # Use git ls-tree to see what's actually in the current branch
        # This avoids being confused by temporary conflict files
        try:
            output = git("ls-tree", "--name-only", "HEAD", "cookbooks/")
            cookbooks = []

            for name in output.splitlines():
                if not name.startswith("cookbooks/"):
                    continue

                cookbook = name.replace("cookbooks/", "")

                # Filter by prefix
                if (
                    cookbook.startswith(prefix)
                    and cookbook not in ignore_cookbooks
                ):
                    cookbooks.append(cookbook)

            self.logger.debug(
                f"Found {len(cookbooks)} local cookbooks: {', '.join(cookbooks)}"
            )
            return cookbooks
        except RuntimeError:
            # If git command fails (e.g., empty repo), fall back to filesystem check
            self.logger.debug(
                "Git ls-tree failed, falling back to filesystem check"
            )
            path = Path("cookbooks")
            if not path.exists():
                self.logger.debug("cookbooks directory does not exist")
                return []

            cookbooks = []
            for p in path.iterdir():
                if not p.is_dir():
                    continue

                cookbook = p.name

                # Filter by prefix
                if (
                    cookbook.startswith(prefix)
                    and cookbook not in ignore_cookbooks
                ):
                    cookbooks.append(cookbook)

            self.logger.debug(
                f"Found {len(cookbooks)} local cookbooks: {', '.join(cookbooks)}"
            )
            return cookbooks

    def detect_global_baseline(self, upstream_config: Dict) -> Optional[str]:
        """
        Detect the baseline commit for an upstream by checking all local cookbooks.

        Args:
            upstream_config: Upstream configuration dict

        Returns:
            Baseline commit SHA or None
        """
        self.logger.info(
            f"Detecting global baseline for {upstream_config['prefix']}"
        )
        cookbooks = self.list_local_cookbooks(upstream_config)
        if not cookbooks:
            self.logger.warning(
                f"No local cookbooks found for {upstream_config['prefix']}"
            )
            return None

        self.logger.debug(f"Checking baselines for {len(cookbooks)} cookbooks")
        matches = []
        for cb in cookbooks:
            commit = self.find_baseline_for_cookbook(cb, upstream_config)
            if commit:
                matches.append(commit)

        if not matches:
            self.logger.warning("No baseline matches found for any cookbook")
            return None

        self.logger.debug(f"Found {len(matches)} baseline matches")
        base = matches[0]
        for m in matches[1:]:
            self.logger.debug(f"Computing merge-base of {base[:8]} and {m[:8]}")
            base = git("merge-base", base, m)

        self.logger.info(f"Global baseline detected at {base}")
        return base

    def find_baseline_for_cookbook(
        self, cb: str, upstream_config: Dict
    ) -> Optional[str]:
        """
        Find the baseline commit for a cookbook in an upstream.

        Args:
            cb: Cookbook name
            upstream_config: Upstream configuration dict

        Returns:
            Baseline commit SHA or None
        """
        remote = upstream_config["remote"]
        branch = upstream_config["branch"]

        self.logger.info(f"Finding baseline for cookbook: {cb}")
        upstream_commits = git(
            "rev-list",
            "--reverse",
            f"{remote}/{branch}",
        ).splitlines()
        self.logger.debug(
            f"Checking {len(upstream_commits)} upstream commits for {cb}"
        )
        for commit in reversed(upstream_commits):
            ok, _, _ = try_git(
                "diff", "--quiet", commit, "--", f"cookbooks/{cb}"
            )
            if ok:
                self.logger.info(f"Baseline match for {cb} at {commit}")
                return commit
        self.logger.info(f"No baseline match found for {cb}")
        return None

    def detect_local_changes(self, cookbook: str) -> bool:
        """
        Detect if a cookbook has local changes.

        Args:
            cookbook: Cookbook name

        Returns:
            True if cookbook has local changes
        """
        self.logger.debug(f"Detecting local changes in cookbook: {cookbook}")
        success, _, _ = try_git(
            "diff", "--quiet", self.base_branch, "--", f"cookbooks/{cookbook}"
        )
        has_changes = not success
        self.logger.debug(
            f"Cookbook {cookbook} has local changes: {has_changes}"
        )
        return has_changes

    def sync(self) -> None:
        """
        Sync all configured upstreams. Each upstream is processed independently
        with its own PR and issue tracking.
        """
        self.logger.info("Starting sync operation")
        self.logger.debug(f"Config: self.base_branch={self.base_branch}")
        self.logger.debug(
            f"Config: self.dry_run={self.dry_run}, self.force_bootstrap={self.force_bootstrap}"
        )

        # Fetch all upstreams
        self.fetch_upstream()

        # Sync each upstream independently
        for prefix, upstream_config in self.upstreams.items():
            self.logger.info(f"Processing upstream: {prefix}")
            self._sync_upstream(upstream_config)

        self.logger.info("Sync operation complete for all upstreams")

    def _sync_upstream(self, upstream_config: Dict) -> None:
        """
        Sync a single upstream.

        Args:
            upstream_config: Upstream configuration dict
        """
        prefix = upstream_config["prefix"]
        trailer_key = upstream_config["trailer_key"]
        remote = upstream_config["remote"]
        branch = upstream_config["branch"]

        self.logger.info(f"Starting sync for upstream: {prefix}")
        self.logger.debug(f"  Remote: {remote}")
        self.logger.debug(f"  Branch: {branch}")
        self.logger.debug(f"  Trailer: {trailer_key}")

        # Checkout branch before each upstream sync
        self.logger.debug(f"Checking out branch: {self.base_branch}")
        git("checkout", self.base_branch)

        pointer = (
            None
            if self.force_bootstrap
            else self.get_current_pointer(upstream_config)
        )
        self.logger.debug(f"Current pointer for {prefix}: {pointer}")

        # ---------------------------
        # ONBOARDING MODE
        # ---------------------------
        if pointer is None:
            self.logger.info(
                f"No upstream pointer found for {prefix}, entering onboarding mode"
            )
            baseline = self.detect_global_baseline(upstream_config)
            if not baseline:
                self.logger.error(
                    f"Unable to detect upstream baseline for {prefix}"
                )
                # Don't exit, continue with other upstreams
                return

            self.create_onboarding_pr(baseline, trailer_key)
            return

        # ---------------------------
        # NORMAL SYNC MODE
        # ---------------------------
        self.logger.info(f"Entering normal sync mode for {prefix}")

        # Close any conflict issues for commits we've successfully synced past
        if pointer:
            self.logger.debug(
                f"Checking for resolved conflict issues to close for {prefix}"
            )
            self.close_resolved_conflict_issues(pointer, dry_run=self.dry_run)

        commits = self.upstream_commits_since(pointer, upstream_config)
        if not commits:
            self.logger.info(f"No new commits to sync for {prefix}")
            return

        self.logger.info(
            f"Found {len(commits)} commits to process for {prefix}"
        )

        # Branch name includes the prefix to keep upstreams separate
        sync_branch = f"{self.pr_branch_prefix}/{prefix}update"
        self.logger.debug(f"Checking out sync branch: {sync_branch}")
        git("checkout", "-B", sync_branch, self.base_branch)

        applied = []
        conflict_occurred = False

        for c in commits:
            self.logger.debug(f"Processing commit: {c[:8]}")
            files = git(
                "show", "--name-only", "--pretty=format:", c
            ).splitlines()
            cookbooks_touched = {
                f.split("/")[1]
                for f in files
                if f.startswith(f"cookbooks/{prefix}") and "/" in f
            }
            self.logger.debug(
                f"Cookbooks touched by {c[:8]}: {', '.join(cookbooks_touched) if cookbooks_touched else 'none'}"
            )
            relevant_cookbooks = cookbooks_touched & set(
                self.list_local_cookbooks(upstream_config)
            )
            self.logger.debug(
                f"Relevant cookbooks: {', '.join(relevant_cookbooks) if relevant_cookbooks else 'none'}"
            )

            if not relevant_cookbooks:
                self.logger.info(
                    f"Skipping {c[:8]} - no relevant cookbooks for {prefix}"
                )
                continue

            try:
                # Attempt cherry-pick
                self.logger.info(f"Applying commit {c[:8]}")
                was_applied = self.cherry_pick_with_trailer(c, upstream_config)
                if was_applied:
                    applied.append(c)
                    self.logger.debug(f"Successfully applied {c[:8]}")
                else:
                    self.logger.debug(
                        f"Skipped {c[:8]} (already applied or no relevant changes)"
                    )
                # Don't create issues on successful applies - only on conflicts

            except RuntimeError as e:
                # Conflict occurred - check for local changes now
                conflict_occurred = True
                self.logger.info(f"Conflict while applying {c[:8]}")

                local_changes = [
                    cb
                    for cb in relevant_cookbooks
                    if self.detect_local_changes(cb)
                ]

                # Always create an issue for conflicting cookbooks
                # Prefer reporting specific local_changes if detected, otherwise report all relevant cookbooks
                cookbooks_to_report = (
                    local_changes if local_changes else list(relevant_cookbooks)
                )

                if local_changes:
                    self.logger.warning(
                        f"Conflict with detected local changes in: {', '.join(local_changes)}"
                    )
                else:
                    self.logger.warning(
                        f"Conflict in {', '.join(relevant_cookbooks)} (no specific local changes detected)"
                    )

                # Extract conflict details if available from the exception
                self.logger.debug(
                    f"Exception type: {type(e).__name__}, has conflict_details attribute: {hasattr(e, 'conflict_details')}"
                )
                conflict_details = getattr(e, "conflict_details", None)
                self.logger.debug(
                    f"Extracted conflict_details: {conflict_details[:200] if conflict_details else 'None'}"
                )

                # Create a single issue for the conflict
                self.create_conflict_issue(
                    commit=c,
                    cookbooks=cookbooks_to_report,
                    conflict_details=conflict_details,
                    dry_run=self.dry_run,
                )
                break  # Stop immediately after first conflict

        # ---------------------------
        # Push branch and create/update PR
        # ---------------------------
        if applied:
            self.logger.info(
                f"Successfully applied {len(applied)} commits for {prefix}"
            )

            # Close any conflict issues for commits we just successfully applied
            if applied and not conflict_occurred:
                self.logger.debug(
                    f"Closing conflict issues for successfully applied commits for {prefix}"
                )
                # The latest applied commit is our new effective pointer
                latest_applied = applied[-1]
                self.close_resolved_conflict_issues(
                    latest_applied, dry_run=self.dry_run
                )

            if not self.dry_run:
                self.logger.info(
                    f"Pushing branch {sync_branch} to {self.target_remote}"
                )
                git("push", "-f", self.target_remote, sync_branch)
            else:
                self.logger.debug(f"[dry-run] Would push branch {sync_branch}")

            pr = self.existing_sync_pr(upstream_config)
            if pr:
                self.logger.info(
                    f"Updating existing PR #{pr['number']} for {prefix}"
                )
                self.update_pr_body(pr["number"], applied, trailer_key)
            else:
                self.logger.info(f"Creating new PR for {prefix}")
                self.create_pr(sync_branch, applied, trailer_key)
        else:
            self.logger.info(f"No commits were applied for {prefix}")

        # ---------------------------
        # Check for remaining local changes after successful sync
        # ---------------------------
        # Only check for local changes if we didn't encounter a conflict
        # (conflicts mean we're not fully synced, so local change detection is
        # unreliable)
        if not conflict_occurred:
            self.logger.info(
                f"Checking for remaining local changes after successful sync for {prefix}"
            )
            all_local_cookbooks = self.list_local_cookbooks(upstream_config)
            cookbooks_with_local_changes = [
                cb
                for cb in all_local_cookbooks
                if self.detect_local_changes(cb)
            ]

            if cookbooks_with_local_changes:
                self.logger.warning(
                    f"Found {len(cookbooks_with_local_changes)} cookbooks with local changes: {', '.join(cookbooks_with_local_changes)}"
                )
                # Create issues for each cookbook with local changes
                # Note: these didn't cause conflicts
                for cookbook in cookbooks_with_local_changes:
                    self.logger.info(
                        f"Creating issue for local changes in {cookbook}"
                    )
                    # Use the last applied commit as reference
                    self.create_or_update_issue_for_local_changes(
                        [cookbook],
                        commit=applied[-1],
                        dry_run=self.dry_run,
                    )
            else:
                self.logger.debug(
                    f"No remaining local changes detected for {prefix}"
                )

        self.logger.info(
            f"Sync complete for {prefix}: {len(applied)} commits applied"
        )

    def parse_command(self, body: str) -> Optional[Tuple[str, str]]:
        """
        Parse a bot command from a comment body.

        Args:
            body: Comment body text

        Returns:
            Tuple of (command_name, command_args) or None if no command found

        Example:
            "#linecook split abc123-def456" returns ("split", "abc123-def456")
            "#linecook rebase" returns ("rebase", "")
        """
        self.logger.debug("Parsing bot command from comment body")
        cmd_pfx = self.config.get("bot_command_prefix")
        regex = r"%s\s+(\w+)(?:\s+(.+))?" % cmd_pfx
        match = re.search(regex, body, re.IGNORECASE)
        if not match:
            self.logger.debug("No bot command found")
            return None

        command = match.group(1).lower()
        args = match.group(2).strip() if match.group(2) else ""

        self.logger.debug(f"Bot command found: {command} with args: {args!r}")
        return (command, args)

    def parse_split_args(self, args: str) -> Optional[Tuple[str, str]]:
        """
        Parse split command arguments to extract the two commit SHAs.

        Args:
            args: Command arguments (e.g., "abc123-def456")

        Returns:
            Tuple of (start_sha, end_sha) or None if invalid
        """
        self.logger.debug(f"Parsing split args: {args}")
        match = re.search(r"([0-9a-f]{7,40})-([0-9a-f]{7,40})", args)
        if not match:
            self.logger.debug("Invalid split args format")
            return None
        split_range = (match.group(1), match.group(2))
        self.logger.debug(f"Split range: {split_range[0]}-{split_range[1]}")
        return split_range

    def cmd_split(
        self,
        args: str,
        pr_number: int,
    ) -> None:
        """
        Handle the 'split' command.

        Args:
            args: Command arguments (e.g., "abc123-def456")
            pr_number: PR number to operate on
        """
        self.logger.info("Running split operation")
        self.logger.debug(f"Processing split on PR #{pr_number}")

        # Parse the split args to extract the two SHAs
        parsed = self.parse_split_args(args)
        if not parsed:
            self.logger.error(f"Invalid split args format: {args}")
            self.logger.error("Expected format: <sha1>-<sha2>")
            raise ValueError(
                f"Invalid split command format. Expected `split <sha1>-<sha2>`, got `{args}`"
            )

        start_sha, end_sha = parsed
        self.logger.info(f"Split command: {start_sha}-{end_sha}")

        # Fetch PR details
        self.logger.debug(f"Fetching PR #{pr_number} details")
        pr_info = run(
            [
                "gh",
                "pr",
                "view",
                str(pr_number),
                "--json",
                "number,headRefName,body",
            ]
        )
        pr = json.loads(pr_info)

        # Determine which upstream this PR belongs to
        upstream_config = self._determine_upstream_from_pr(pr)
        if not upstream_config:
            raise ValueError(
                "Could not determine which upstream this PR belongs to"
            )

        trailer_key = upstream_config["trailer_key"]
        prefix = upstream_config["prefix"]
        self.logger.debug(
            f"PR belongs to upstream: {prefix}, using trailer: {trailer_key}"
        )

        branch = pr["headRefName"]
        self.logger.debug(f"Processing split on branch: {branch}")
        git("checkout", branch)

        # Get branch commits mapped to their upstream commits (commits that
        # were successfully applied)
        branch_commits = self.get_branch_commits_with_trailers(
            branch, trailer_key
        )
        upstream_to_branch = {
            upstream: branch for branch, upstream in branch_commits
        }

        # Get the intended upstream commits from the PR body
        pr_body = pr.get("body", "")
        intended_upstream = re.findall(
            rf"{re.escape(trailer_key)}:\s*([0-9a-f]{{40}})", pr_body
        )
        self.logger.debug(
            f"Found {len(intended_upstream)} intended upstream commits in PR body"
        )

        # Build map for lookup using intended commits (what SHOULD be synced)
        trailers_map = {t[:8]: t for t in intended_upstream}

        self.logger.debug(
            f"Intended upstream commits (first 8 chars): {list(trailers_map.keys())}"
        )
        self.logger.debug(
            f"Looking for start={start_sha[:8]}, end={end_sha[:8]}"
        )

        start = trailers_map.get(start_sha[:8])
        end = trailers_map.get(end_sha[:8])

        if not start or not end:
            self.logger.error(
                f"Invalid split SHAs: start={start_sha}, end={end_sha}"
            )
            self.logger.error(
                f"Intended upstream commits in PR: {list(trailers_map.keys())}"
            )
            available_shas = ", ".join(list(trailers_map.keys())[:10])
            if len(trailers_map) > 10:
                available_shas += f", ... ({len(trailers_map)} total)"
            raise ValueError(
                f"Invalid commit SHAs. Could not find `{start_sha[:8]}` or `{end_sha[:8]}` in this PR. "
                f"Available SHAs: {available_shas}"
            )

        start_idx = intended_upstream.index(start)
        end_idx = intended_upstream.index(end)

        # Ensure start_idx is before end_idx (handle user providing them in any order)
        if start_idx > end_idx:
            self.logger.debug(f"Swapping range order: {start_idx} > {end_idx}")
            start_idx, end_idx = end_idx, start_idx

        self.logger.debug(f"Split range indices: {start_idx} to {end_idx}")

        # Validate that the split is contiguous (from one end, not the middle)
        if start_idx != 0 and end_idx != len(intended_upstream) - 1:
            self.logger.error(
                f"Split must be from one end: either start at 0 or end at {len(intended_upstream) - 1}"
            )
            self.logger.error(f"Got: start_idx={start_idx}, end_idx={end_idx}")
            raise ValueError(
                f"Split must be contiguous from one end of the PR, not from the middle. "
                f"The range `{start_sha[:8]}-{end_sha[:8]}` is in the middle (positions {start_idx} to {end_idx} "
                f"out of {len(intended_upstream)} commits). Please choose a range that starts at the beginning "
                f"or ends at the end of the commit list."
            )

        # Get the upstream commits for each range from the PR body
        first_range_upstream = intended_upstream[start_idx : end_idx + 1]
        second_range_upstream = (
            intended_upstream[end_idx + 1 :]
            if end_idx < len(intended_upstream) - 1
            else []
        )

        # Get the branch commits that were actually applied (some might have failed)
        first_range_branch = [
            upstream_to_branch.get(u) for u in first_range_upstream
        ]
        second_range_branch = [
            upstream_to_branch.get(u) for u in second_range_upstream
        ]

        self.logger.debug(
            f"First range: {len(first_range_upstream)} upstream commits, "
            f"Second range: {len(second_range_upstream)} upstream commits"
        )

        # Rewrite original PR branch
        self.logger.info(
            f"Rewriting original PR branch {branch} with first range"
        )
        git("checkout", self.base_branch)
        git("branch", "-D", branch)
        git("checkout", "-b", branch, self.base_branch)

        for i, upstream_commit in enumerate(first_range_upstream):
            branch_commit = first_range_branch[i]
            if branch_commit:
                # Commit was already applied to branch, cherry-pick the resolved version
                self.logger.debug(
                    f"Cherry-picking resolved branch commit {branch_commit[:8]} (upstream {upstream_commit[:8]})"
                )
                git("cherry-pick", branch_commit)
            else:
                # Commit not yet applied, use cherry_pick_with_trailer
                self.logger.debug(
                    f"Applying upstream commit {upstream_commit[:8]} with trailer"
                )
                self.cherry_pick_with_trailer(upstream_commit, upstream_config)

        if not self.dry_run:
            self.logger.info(f"Pushing rewritten branch {branch}")
            git("push", "-f", self.target_remote, branch)
            self.update_pr_body(pr_number, first_range_upstream, trailer_key)

            # Add split label to the first PR
            split_label = self.config.get("split_label")
            self.logger.info(f"Adding {split_label} label to PR #{pr_number}")
            run(
                ["gh", "pr", "edit", str(pr_number), "--add-label", split_label]
            )
        else:
            self.logger.info(
                f"[dry-run] Would rewrite original PR branch {branch} with {len(first_range_upstream)} commits"
            )

        if second_range_upstream:
            new_branch = f"{self.pr_branch_prefix}/{prefix}{second_range_upstream[0][:8]}"
            self.logger.info(
                f"Creating new branch {new_branch} for second range"
            )
            git("checkout", "-b", new_branch, self.base_branch)

            for i, upstream_commit in enumerate(second_range_upstream):
                branch_commit = second_range_branch[i]
                if branch_commit:
                    # Commit was already applied to branch, cherry-pick the resolved version
                    self.logger.debug(
                        f"Cherry-picking resolved branch commit {branch_commit[:8]} (upstream {upstream_commit[:8]})"
                    )
                    git("cherry-pick", branch_commit)
                else:
                    # Commit not yet applied, use cherry_pick_with_trailer
                    self.logger.debug(
                        f"Applying upstream commit {upstream_commit[:8]} with trailer"
                    )
                    self.cherry_pick_with_trailer(
                        upstream_commit, upstream_config
                    )

            if not self.dry_run:
                self.logger.info(f"Pushing new branch {new_branch}")
                git("push", "-f", self.target_remote, new_branch)
                new_pr_number = self.create_pr(
                    new_branch, second_range_upstream, trailer_key
                )

                if new_pr_number:
                    # Add split label to the second PR
                    split_label = self.config.get("split_label")
                    self.logger.info(
                        f"Adding {split_label} label to PR #{new_pr_number}"
                    )
                    run(
                        [
                            "gh",
                            "pr",
                            "edit",
                            str(new_pr_number),
                            "--add-label",
                            split_label,
                        ]
                    )
            else:
                self.logger.info(
                    f"[dry-run] Would create new PR {new_branch} with {len(second_range_upstream)} commits"
                )
        else:
            self.logger.debug("No second range to process")

        # Add success comment
        if not self.dry_run:
            if second_range_upstream:
                success_msg = (
                    f"✅ Split completed successfully!\n\n"
                    f"- Updated this PR with {len(first_range_upstream)} commit(s)\n"
                    f"- Created new PR #{new_pr_number} with {len(second_range_upstream)} commit(s)"
                )
            else:
                success_msg = (
                    f"✅ Split completed successfully!\n\n"
                    f"- Updated this PR with {len(first_range_upstream)} commit(s)"
                )
            self.add_comment(pr_number, success_msg)

    def cmd_rebase(self, args: str, pr_number: int) -> None:
        """
        Handle the 'rebase' command.

        Args:
            args: Command arguments (currently unused)
            pr_number: PR number to rebase
        """
        self.logger.info(f"Executing rebase command on PR #{pr_number}")

        # Fetch PR details
        self.logger.debug(f"Fetching PR #{pr_number} details")
        pr_info = run(
            [
                "gh",
                "pr",
                "view",
                str(pr_number),
                "--json",
                "number,headRefName,body",
            ]
        )
        pr = json.loads(pr_info)

        # Determine which upstream this PR belongs to
        upstream_config = self._determine_upstream_from_pr(pr)
        if not upstream_config:
            raise ValueError(
                "Could not determine which upstream this PR belongs to"
            )

        trailer_key = upstream_config["trailer_key"]
        prefix = upstream_config["prefix"]
        self.logger.debug(
            f"PR belongs to upstream: {prefix}, using trailer: {trailer_key}"
        )

        branch = pr["headRefName"]
        self.logger.debug(f"Rebasing branch: {branch}")

        # Fetch the latest changes from base branch
        self.logger.info(f"Fetching latest {self.base_branch}")
        git("fetch", self.target_remote, self.base_branch)

        # Checkout the PR branch
        git("checkout", branch)

        # Get the upstream commits from the PR body before rebase
        pr_body = pr.get("body", "")
        intended_upstream = re.findall(
            rf"{re.escape(trailer_key)}:\s*([0-9a-f]{{40}})", pr_body
        )
        self.logger.debug(
            f"Found {len(intended_upstream)} intended upstream commits in PR body"
        )

        # Perform the rebase
        self.logger.info(
            f"Rebasing {branch} onto {self.target_remote}/{self.base_branch}"
        )
        try:
            git("rebase", f"{self.target_remote}/{self.base_branch}")
        except RuntimeError as e:
            self.logger.error(f"Rebase failed: {e}")
            raise ValueError(
                f"Rebase failed with conflicts. Please resolve conflicts manually. "
                f"You may need to checkout the branch locally and run:\n"
                f"```\n"
                f"git checkout {branch}\n"
                f"git rebase origin/{self.base_branch}\n"
                f"# Resolve conflicts\n"
                f"git rebase --continue\n"
                f"git push --force-with-lease\n"
                f"```"
            )

        if not self.dry_run:
            self.logger.info(f"Pushing rebased branch {branch}")
            git("push", "--force-with-lease", self.target_remote, branch)

            # Add success comment
            commit_count = (
                len(intended_upstream) if intended_upstream else "all"
            )
            success_msg = (
                f"✅ Rebase completed successfully!\n\n"
                f"- Rebased {commit_count} commit(s) onto latest `{self.base_branch}`\n"
                f"- Branch `{branch}` has been updated"
            )
            self.add_comment(pr_number, success_msg)
        else:
            self.logger.info(
                f"[dry-run] Would rebase branch {branch} onto {self.base_branch}"
            )

    def handle_command(
        self,
        comment_body: Optional[str] = None,
        pr_number: Optional[int] = None,
    ) -> None:
        """
        Parse and dispatch bot commands from PR comments.

        Args:
            comment_body: Comment body text (if None, reads from event)
            pr_number: PR number (if None, reads from event)
        """
        # If not called with explicit params, read from GitHub event
        if comment_body is None or pr_number is None:
            self.logger.debug(
                f"Reading GitHub event from: {self.github_event_path}"
            )
            with open(self.github_event_path) as f:
                event = json.load(f)

            if "issue" not in event or "pull_request" not in event["issue"]:
                self.logger.info("Not a PR comment event, skipping")
                self.logger.debug("Event info: %s", json.dumps(event, indent=2))
                return

            comment_body = event["comment"]["body"]
            pr_number = event["issue"]["number"]

        self.logger.debug(f"Processing comment on PR #{pr_number}")

        # Parse the command
        parsed = self.parse_command(comment_body)
        if not parsed:
            self.logger.debug("No bot command found in comment, skipping")
            return

        command, args = parsed
        self.logger.info(f"Dispatching command: {command} with args: {args!r}")

        # Dispatch to appropriate handler
        try:
            if command == "split":
                self.cmd_split(args=args, pr_number=pr_number)
            elif command == "rebase":
                self.cmd_rebase(args, pr_number)
            else:
                # Unknown command - comment on the PR
                self.logger.warning(f"Unknown command: {command}")
                error_msg = (
                    f"❌ Unknown command: `{command}`\n\n"
                    f"Supported commands:\n"
                    f"- `split <sha1>-<sha2>` - Split a PR into two PRs\n"
                    f"- `rebase` - Rebase the PR onto the latest base branch\n"
                )
                self.add_comment(pr_number, error_msg)
        except Exception as e:
            # Command execution failed - comment on the PR
            self.logger.error(f"Command execution failed: {e}", exc_info=True)
            error_msg = (
                f"❌ Failed to execute command `{command}`\n\n"
                f"**Error:** {str(e)}\n\n"
                f"Please check the command syntax and try again. "
                f"See the bot logs for more details."
            )
            self.add_comment(pr_number, error_msg)

    def bot_created_pr_or_issue_closed(self, event: dict) -> bool:
        """
        Check if a PR/issue close event is for one of our bot-created items.

        Args:
            event: GitHub event dict

        Returns:
            True if this is a bot-created PR/issue that was closed
        """
        action = event.get("action")
        if action != "closed":
            self.logger.debug(
                f"Ignoring {self.github_event_name} event with action: {action}"
            )
            return False

        self.logger.debug(
            f"Checking if closed event for {self.github_event_name} has our label"
        )
        # Check if the PR/issue has our label
        labels = []
        if "pull_request" in event:
            labels = [
                label["name"]
                for label in event["pull_request"].get("labels", [])
            ]
        elif "issue" in event:
            labels = [
                label["name"] for label in event["issue"].get("labels", [])
            ]

        bot_label = self.config.get("bot_label")
        has_bot_label = bot_label in labels

        return has_bot_label


# ===================================================
# Main Entry Point
# ===================================================


def main() -> None:
    parser = argparse.ArgumentParser(description="Facebook Chef Sync Bot")
    parser.add_argument(
        "--dry-run",
        "-n",
        action="store_true",
        help="Do not push branches, PRs, or file issues",
    )
    parser.add_argument(
        "--force-bootstrapping",
        action="store_true",
        help="Ignore current upstream pointer",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        default="info",
        choices=["debug", "info", "warning", "error", "critical"],
        help="Set the logging level (default: info)",
    )
    parser.add_argument(
        "--command",
        help="Test bot command (e.g., 'split abc123-def456' or 'rebase'), requires --pr",
    )
    parser.add_argument(
        "--pr",
        type=int,
        help="PR number to test command on (requires --command)",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level.upper()),
        format="[%(asctime)s] %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logger = logging.getLogger(__name__)

    config = load_config()

    bot = LineCook(
        config=config,
        dry_run=args.dry_run,
        force_bootstrap=args.force_bootstrapping,
    )

    logger.info(f"Starting line-cook (log level: {args.log_level})")

    github_event_name = os.environ.get("GITHUB_EVENT_NAME")
    github_event_path = os.environ.get("GITHUB_EVENT_PATH")

    # Determine which mode to run in
    if args.command and args.pr:
        # Command line test mode - construct a comment body with the command
        logger.info(f"Running command test (PR #{args.pr}): {args.command}")
        comment_body = f"{config.get('bot_command_prefix')} {args.command}"
        logger.debug(f"Constructed comment body for test: {comment_body}")
        bot.handle_command(comment_body=comment_body, pr_number=args.pr)
    elif args.command or args.pr:
        logger.error("Both --command and --pr required for test mode")
        sys.exit(1)
    elif github_event_name == "issue_comment":
        # PR comment with bot command
        logger.info("Running in command mode (issue_comment event)")
        bot.handle_command()
    elif (
        github_event_name in ("issues", "pull_request_target")
        and github_event_path
    ):
        # We will be notified anytime an issue or pull request close, and
        # run a sync again instead of waiting for the next scheduled run.

        # However, for PRs we don't want to run in PR context, so we use
        # pull_request_target for these. If it's `pull_request`, it's
        # a different case.

        # Check if this is a close event on a PR/issue with our labels
        logger.debug(f"Checking {github_event_name} event")
        should_sync = False
        try:
            with open(github_event_path) as f:
                event = json.load(f)

            should_sync = bot.bot_created_pr_or_issue_closed(event)
        except Exception as e:
            logger.warning(f"Error processing {github_event_name} event: {e}")
            logger.info("Not running any mode...")

        if should_sync:
            logger.info("PR/Issue with bot label closed, running sync mode")
            bot.sync()
        else:
            logger.info("Not one of our issues/PRs being closed, ignoring.")

    else:
        # Default: sync mode (scheduled runs, workflow_dispatch, etc.)
        logger.info("Running in sync mode")
        bot.sync()

    logger.info("line-cook completed")


if __name__ == "__main__":
    main()
