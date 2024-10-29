#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][Alias('sourceBranch')][String] $source,
    [Parameter(Mandatory)][Alias('targetBranch')][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [Parameter()][String[]] $preserve = @(),
    [switch] $cleanupOnly,
    [switch] $force,
    [switch] $noFetch,
    [switch] $quiet,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/actions.psm1"

$diagnostics = New-Diagnostics
$config = Get-Configuration
if (-not $noFetch) {
    Update-GitRemote -quiet:$quiet
}

$commonParams = @{
    diagnostics = $diagnostics
}

# Assert up-to-date
# a) if $cleanupOnly, ensure no commits are in source that are not in target
# b) otherwise, ensure no commits are in target that are not in source
if (-not $force) {
    Invoke-LocalAction @commonParams @{
        type = 'assert-updated'
        parameters = $cleanupOnly `
            ? @{ downstream = $target; dependency = $source }
            : @{ downstream = $source; dependency = $target }
    }
    Assert-Diagnostics $diagnostics
}

# $toRemove = (git show-deps $source -recurse) without ($target, git show-deps $target -recurse, $preserve)
$sourceDependency = Invoke-LocalAction @commonParams @{
    type = 'get-dependency'
    parameters = @{ target = $source; recurse = $true }
}
Assert-Diagnostics $diagnostics

$targetDependency = Invoke-LocalAction @commonParams @{
    type = 'get-dependency'
    parameters = @{ target = $target; recurse = $true }
}
Assert-Diagnostics $diagnostics

[string[]]$keep = @($target) + $targetDependency + $preserve
[string[]]$toRemove = (@($source) + $sourceDependency) | Where-Object { $_ -notin $keep }

# Assert all branches removed are up-to-date, unless $force is set
if (-not $force) {
    foreach ($branch in $toRemove) {
        if ($branch -eq $source) { continue }
        Invoke-LocalAction @commonParams @{
            type = 'assert-updated'
            parameters = @{ downstream = $cleanupOnly ? $target : $source; dependency = $branch }
        }
    }
    Assert-Diagnostics $diagnostics
}

# For all branches:
#    1. Replace $toRemove branches with $target
#    2. Simplify

$originalDependencies = Invoke-LocalAction @commonParams @{
    type = 'get-all-dependencies'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

$resultDependencies = @{}
foreach ($branch in $originalDependencies.Keys) {
    if ($branch -in $toRemove) {
        $resultDependencies[$branch] = $null
        continue
    }

    if ($originalDependencies[$branch] | Where-Object { $_ -in $toRemove }) {
        $resultDependencies[$branch] = Invoke-LocalAction @commonParams @{
            type = 'filter-branches'
            parameters = @{
                include = @($target) + $originalDependencies[$branch]
                exclude = $toRemove
            }
        }
        Assert-Diagnostics $diagnostics
    }
}

$keys = @() + $resultDependencies.Keys
foreach ($branch in $keys) {
    if (-not $resultDependencies[$branch]) { continue }
    $resultDependencies[$branch] = Invoke-LocalAction @commonParams @{
        type = 'simplify-dependency'
        parameters = @{
            dependencyBranches = $resultDependencies[$branch]
            overrideDependencies = $resultDependencies
            branchName = $branch
        }
    }
    Assert-Diagnostics $diagnostics
}

$dependencyHash = Invoke-LocalAction @commonParams @{
    type = 'set-dependency'
    parameters = @{
        dependencyBranches = $resultDependencies
        message = "Release $($source) to $($target)$($comment -eq '' ? '' : " for $($params.comment)")"
    }
}
Assert-Diagnostics $diagnostics

$sourceHash = Get-BranchCommit (Get-RemoteBranchRef $source)

# Finalize:
#    1. Push the following:
#        - Update $dependencies
#        - Delete $toRemove branches
#        - If not $cleanupOnly, push $source commitish to $target

$commonParams = @{
    diagnostics = $diagnostics
    dryRun = $dryRun
}

$resultBranches = @{
    "$($config.dependencyBranch)" = $dependencyHash.commit
}
foreach ($branch in $toRemove) {
    $resultBranches[$branch] = $null
}
if (-not $cleanupOnly) {
    $resultBranches[$target] = $sourceHash
}

Invoke-FinalizeAction @commonParams @{
    type = 'set-branches'
    parameters = @{
        branches = $resultBranches
    }
}
Assert-Diagnostics $diagnostics
