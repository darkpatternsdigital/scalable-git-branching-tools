#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates a new branch and checks it out from the specified branches

.PARAMETER branchName
    Specifies the name of the branch.

.PARAMETER comment
    Specifies a comment as part of the commit message for the dependency branch.

.PARAMETER dependencyBranches
    A comma-delimited list of branches (without the remote, if applicable). If not specified, assumes the default service line (see [tool-config](./tool-config.md).)

.PARAMETER dryRun
    If specified, only test merging, do not push the updates.
#>
Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('d')][Alias('dependency')][Alias('dependencies')][String[]] $dependencyBranches,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-new.json" -params @{
    branchName = $branchName;
    dependencyBranches = Expand-StringArray $dependencyBranches;
    comment = $comment ?? '';
} -dryRun:$dryRun
