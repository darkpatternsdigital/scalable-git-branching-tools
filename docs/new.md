# `git new`

Creates a new branch and checks it out from the specified branches

Usage:

    git-new.ps1 [-branchName] <string> [[-comment] <string>] `
        [[-parentBranches] <string[]>] [-noFetch]

## Parameters:

### `[-branchName] <string>`

Specifies the name of the branch. 

### `[-comment] <string>` (Optional)

Specifies a comment as part of the commit message for the upstream branch.

### `-parentBranches <string>` (Optional)

A comma-delimited list of branches (without the remote, if applicable). If not specified, assumes the default service line (see [tool-config](./tool-config.md).)

### `[-noFetch]` (Optional)

If specified, branch will be created without fetching from the remote first.