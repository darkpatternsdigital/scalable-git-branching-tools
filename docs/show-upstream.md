# `git show-upstream`

Shows what the upstream branches are of the current (or specified) branch.

Usage:

    git-show-upstream.ps1 [[-branchName] <string>] [-recurse] 

## Parameters

### `[-branchName] <string>` (Optional)

The name of the branch to list upstream branches. If not specified, use the current branch.

### `-recurse` (Optional)

If specified, list all upstream branches recursively.