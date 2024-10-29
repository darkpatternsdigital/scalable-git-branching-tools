#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][Alias('d')][Alias('dependency')][Alias('dependencies')][String[]] $dependencyBranches,
    [Parameter()][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-add-deps.json" -params @{
    target = ($target ? $target : (Get-CurrentBranch ?? ''));
    dependencyBranches = Expand-StringArray $dependencyBranches;
    comment = $comment ?? '';
} -dryRun:$dryRun
