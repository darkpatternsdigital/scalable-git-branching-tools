#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $target,
    [Parameter()][Alias('d')][Alias('dependency')][Alias('dependencies')][String[]] $dependencyBranches,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $force,
    [switch] $allowOutOfDate,
    [switch] $allowNoDependencies,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-rc.json" -params @{
    branchName = $target;
    dependencyBranches = Expand-StringArray $dependencyBranches;
    force = [boolean]$force;
    allowOutOfDate = [boolean]$allowOutOfDate;
    allowNoDependencies = [boolean]$allowNoDependencies;
    comment = $comment ?? '';
} -dryRun:$dryRun
