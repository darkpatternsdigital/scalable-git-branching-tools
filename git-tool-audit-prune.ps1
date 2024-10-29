#!/usr/bin/env pwsh

Param(
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
# Get all branches in dependencies

$originalDependencies = Invoke-LocalAction @commonParams @{
    type = 'get-all-dependencies'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

# Get branches that actually exist

$allBranches = Select-Branches

# For all keys (downstream) in the dependencies:
#    - If the downstream does not exist, replace it with its downstreams in all other dependencies

[string[]]$configuredBranches = @() + $originalDependencies.Keys
$resultDependencies = @{}
foreach ($branch in $configuredBranches) {
    if ($branch -in $allBranches) { continue }
    [string[]]$dependencies = $resultDependencies[$branch] ?? $originalDependencies[$branch]
    foreach ($downstream in $configuredBranches) {
        [string[]]$initial = $resultDependencies[$downstream] ?? $originalDependencies[$downstream]
        if ($branch -notin $initial) { continue }
        $resultDependencies[$downstream] = Invoke-LocalAction @commonParams @{
            type = 'filter-branches'
            parameters = @{
                include = $initial + $dependencies
                exclude = @($branch)
            }
        }
    }
}


# For all keys (downstream) in the dependencies:
#    - Remove entire branch configuration if the branch does not exist
#    - Remove dependencies that do not exist
foreach ($branch in $configuredBranches) {
    if ($branch -notin $allBranches) {
        $resultDependencies[$branch] = $null
        continue
    }
    [string[]]$dependencies = $resultDependencies[$branch] ?? $originalDependencies[$branch]
    [string[]]$resultDependency = @()
    foreach ($dependency in $dependencies) {
        if ($dependency -in $allBranches) {
            $resultDependency = $resultDependency + @($dependency)
        }
    }
}

# Simplify changed dependencies
foreach ($branch in $configuredBranches) {
    if (-not $resultDependencies[$branch]) { continue }
    [string[]]$result = Invoke-LocalAction @commonParams @{
        type = 'simplify-dependency'
        parameters = @{
            dependencyBranches = $resultDependencies[$branch]
            overrideDependencies = $resultDependencies
            branchName = $branch
        }
    }
    if ($result.length -ne ([string[]]$resultDependencies[$branch]).length) {
        $resultDependencies[$branch] = $result
    }
}
Assert-Diagnostics $diagnostics

# Set dependency branch

if ($resultDependencies.Count -ne 0) {
    $dependencyHash = Invoke-LocalAction @commonParams @{
        type = 'set-dependency'
        parameters = @{
            dependencyBranches = $resultDependencies
            message = "Applied changes from 'prune' audit"
        }
    }
    Assert-Diagnostics $diagnostics
}

# Finalize: Push dependency branch

$commonParams = @{
    diagnostics = $diagnostics
    dryRun = $dryRun
}

if ($resultDependencies.Count -ne 0) {
    Invoke-FinalizeAction @commonParams @{
        type = 'set-branches'
        parameters = @{
            branches = @{
                "$($config.dependencyBranch)" = $dependencyHash.commit
            }
        }
    }
    Assert-Diagnostics $diagnostics
}
