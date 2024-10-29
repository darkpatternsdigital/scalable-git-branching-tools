#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $target,
    [Parameter()][Alias('add')][Alias('addDependency')][Alias('dependencyBranches')][String[]] $with,
    [Parameter()][Alias('remove')][Alias('removeDependency')][String[]] $without,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $allowOutOfDate,
    [switch] $allowNoDependencies,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-rebuild-rc.json" -params @{
    target = $target;
    with = Expand-StringArray $with;
    without = Expand-StringArray $without;
    allowOutOfDate = [boolean]$allowOutOfDate;
    allowNoDependencies = [boolean]$allowNoDependencies;
    comment = $comment ?? '';
} -dryRun:$dryRun
