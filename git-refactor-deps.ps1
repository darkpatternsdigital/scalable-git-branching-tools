#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $source,
    [Parameter(Mandatory)][string] $target,
    [switch] $rename,
    [switch] $combine,
    [switch] $remove,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-refactor-deps.json" -params @{
    source = $source;
    target = $target;
    rename = $rename;
    combine = $combine;
    remove = $remove;
    comment = $comment ?? '';
} -dryRun:$dryRun
