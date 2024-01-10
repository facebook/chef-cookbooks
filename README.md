# ~Facebook~ Etsy Cookbooks Suite

This is a fork of https://github.com/facebook/chef-cookbooks. Ideally we will send pull requests upstream for all of the changes we make here, but this repository serves as a place for us to use changes before they are accepted (if ever).

## Getting started

Clone this repository and ensure that you have added Facebook's repository as a `git` origin:

```
git clone git@github.com:etsy/chef-cookbooks.git
git remote add facebook https://github.com/facebook/chef-cookbooks.git
```

## How-tos

### How to make a change to both upstream and this repository (preferred)

1. Create a branch that tracks Facebook's repository:

   ```
   git checkout -b to-upstream/feat-add-fb-foo --track facebook/main
   ```

2. Create your new cookbook, or edit an existing one.

3. Commit and push your changes.

4. Navigate to `https://github.com/etsy/chef-cookbooks/pull/new/<your-branch-here>` and create a pull request.

   **Note:** make sure the base repository is `facebook/chef-cookbooks`!

5. Now switch back to our `main` branch and create a branch to merge your proposed change in our repository:

   ```
   git checkout main
   git checkout -b to-merge/feat-add-fb-foo
   ```

6. Then merge or cherry-pick your commits from the `to-upstream/feat-add-fb-foo` branch:

   ```
   git merge --squash to-upstream/feat-add-fb-foo
   git push
   ```

7. Navigate to `https://github.com/etsy/chef-cookbooks/compare/main...etsy:chef-cookbooks:to-merge/<your-branch-here>?expand=1` and create a pull request.

   **Note:** make sure the base repository is `etsy/chef-cookbooks`!

8. Get approval on our PR, and merge. See the `README` in our internal Chef repository under the `third-party` directory for instructions on updating our dependency on this repository.

9. Make changes as needed in the upstream pull request, and merge them back into our branch, and repeat steps 5 - 8 as needed.

### How to make a change to just this repository (not preferred)

You should strive to make changes that we can upstream, so that we remain aligned with the community-at-large. If circumstances require that you don't, you can follow this process:

1. Create a branch that tracks our repository:

   ```
   git checkout -b to-merge/feat-add-fb-foo
   ```

2. Create your new cookbook, or edit an existing one.

3. Commit and push your changes.

4. Navigate to `https://github.com/etsy/chef-cookbooks/compare/main...etsy:chef-cookbooks:to-merge/<your-branch-here>?expand=1` and create a pull request.

   **Note:** make sure the base repository is `etsy/chef-cookbooks`!

5. Get approval on our PR, and merge. See the `README` in our internal Chef repository under the `third-party` directory for instructions on updating our dependency on this repository.

### How to use the latest version of this repository

See the instructions in our internal Chef repository under the `third-party` directory.
