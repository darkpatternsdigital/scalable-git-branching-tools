# `git rebuild-rc`

Recreate a branch from its dependency branches, possibly modifying the dependency
branches. Intended for creating release candidate branches.

Usage:

    git-rc.ps1 [-target] <string> [-with <string[]>] [-without <string[]>] [-comment <string>] [-dryRun] [-allowOutOfDate] [-allowNoDependencies]

## Parameters

### `[-target] <string>`

The name of the new branch.

### `-with <string[]>`

_Aliases: -add, -addDependency, -dependencyBranches_

Comma-delimited list of branches to add dependency of the rc when rebuilding

### `-without <string[]>`

_Aliases: -remoce, -removeDependency_

Comma-delimited list of branches to remove dependency of the rc when rebuilding

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, adds to the commit message on the dependency tracking branch for
creating the RC branch.

### `-allowOutOfDate` (Optional)

Allows branches that are not up-to-date with their dependencies.

### `-allowNoDependencies` (Optional)

Allows branches that do not have any dependencies.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.
