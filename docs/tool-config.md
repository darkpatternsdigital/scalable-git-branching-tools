# `git tool-config`

Sets configuration values used by git-tools.

Usage:

    git tool-config [-remote <string>] [-dependencyBranch <string>] `
        [-defaultServiceLine <string>]

## Parameters:

### `-remote <string>` (Optional)

Sets the remote used where the dependency branch is tracked. Most commands will
automatically fetch/push from this remote when set. If not set and the
repository has a remote configured, the first remote will be used.

### `-dependencyBranch <string>` (Optional)

Sets the branch name used to track dependency branches. Defaults to `$dependencies`.

### `-defaultServiceLine <string>` (Optional)

Sets the branch used as the default service line when creating new branches.

### `-enableAtomicPush` (Optional)

If specified, atomic pushes will be enabled.

### `-disableAtomicPush` (Optional)

If specified, atomic pushes will be disabled.
