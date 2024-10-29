# `git add-deps`

Adds one or more dependency branches to an existing branch.

Usage:

    git-add-deps.ps1 [-dependencyBranches] <string[]> [-target <string>] [-comment <string>] [-dryRun]

## Parameters

### `[-dependencyBranches] <string[]>`

_Aliases: -d, -dependency, -dependencies_

A comma-delimited list of branches to add dependency of the existing branch.

### `-target <string>` (Optional)

The existing branch to update. If not specified, use the current branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, include this comment in the commit message for the dependency
tracking branch when pushing changes.

### `-dryRun` (Optional)

If specified, only test merging changes, do not push the updates.
