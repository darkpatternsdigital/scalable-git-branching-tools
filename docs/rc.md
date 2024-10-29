# `git rc`

Create a new branch from multiple dependency branches without changing the local
branch. Intended for creating release candidate branches.

Usage:

    git-rc.ps1 [-target] <string> [-dependencyBranches <string[]>] [-comment <string>] [-force] [-dryRun] [-allowOutOfDate] [-allowNoDependencies]

## Parameters

### `[-target] <string>`

The name of the new branch.

### `-dependencyBranches <string[]>`

_Aliases: -d, -dependency, -dependencies_

Comma-delimited list of branches to merge into the new branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, adds to the commit message on the dependency tracking branch for
creating the RC branch.

### `-force` (Optional)

Forces an update of the RC branch. Use this if you are replacing the existing
branch.

### `-allowOutOfDate` (Optional)

Allows branches that are not up-to-date with their dependencies. (This is the old
behavior.)

### `-allowNoDependencies` (Optional)

Allows branches that do not have any dependencies. (This is the old behavior.)

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.
