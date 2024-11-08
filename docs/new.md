# `git new`

Creates a new branch and checks it out from the specified branches

Usage:

    git-new.ps1 [-branchName] <string> [-comment <string>] `
        [-dependencyBranches <string[]>] [-dryRun]

## Parameters:

### `[-branchName] <string>`

Specifies the name of the branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

Specifies a comment as part of the commit message for the dependency branch.

### `-dependencyBranches <string>` (Optional)

_Aliases: -d, -dependency, -dependencies_

A comma-delimited list of branches (without the remote, if applicable). If not
specified, assumes the default service line (see [tool-config][tool-config].)

### `-fromCurrent` (Optional)

_Aliases: -c_

If specified and on a current branch, include the current branch in the
dependency branches.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.

[tool-config]: ./tool-config.md
