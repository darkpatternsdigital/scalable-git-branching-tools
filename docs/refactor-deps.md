# `git refactor-deps`

Refactor dependency branches to redirect dependencies from "source" to "target".
* _All_ branches that previously used "source" as an dependency will now use
  "target" as an dependency instead.
* This command only alters the dependency configuration of branches. Put another
  way, it does not merge any changes from new dependencies, etc. into affected
  branches, nor does it actually delete a "removed" source.

Usage:

    git-refactor-deps.ps1 [-source] <string> [-target] <string>
        (-remove|-rename|-combine) [-comment <string>] [-dryRun]

## Parameters

### `[-source] <string>`

The name of the old dependency branch.

### `[-target] <string>`

The name of the new dependency branch.

### `(-remove|-rename|-combine)`

One of -rename, -remove, or -combine must be specfied.

* `-remove` indicates that the source branch should be removed and old dependency
  branches can be ignored.
* `-rename` indicates that dependencies from the source branch should be
  transferred to the target branch; any dependencies of the target should be
  overwritten.
* `-combine` indicates that dependencies from both source and target should be
  combined into dependencies of the target branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, include this comment in the commit message for the dependency
tracking branch when pushing changes.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.

