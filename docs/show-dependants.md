# `git show-dependants`

Shows what the dependants branches are of the current (or specified) branch.

Usage:

    git-show-dependants.ps1 [-target <string>] [-recurse] [-noFetch] [-quiet]

## Parameters

### `[-target] <string>` (Optional)

The name of the branch to list dependants branches. If not specified, use the
current branch.

### `-recurse` (Optional)

If specified, list all dependants branches recursively.

## `-noFetch` (Optional)

By default, all scripts fetch the latest before processing. To skip this (which
was the old behavior), include `-noFetch`.

## `-quiet` (Optional)

Suppress unnecessary output. Useful when a tool is designed to consume the
output of this script via git rather than via PowerShell.
