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
# For all branches:
#    Simplify

$originalDependencies = Invoke-LocalAction @commonParams @{
    type = 'get-all-dependencies'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

$resultDependencies = @{}
foreach ($branch in $originalDependencies.Keys) {
    if (-not $originalDependencies[$branch]) { continue }
    [string[]]$result = Invoke-LocalAction @commonParams @{
        type = 'simplify-dependency'
        parameters = @{
            dependencyBranches = $originalDependencies[$branch]
            overrideDependencies = $originalDependencies
            branchName = $branch
        }
    }
    if ($result.length -ne ([string[]]$originalDependencies[$branch]).length) {
        $resultDependencies[$branch] = $result
    }
}
Assert-Diagnostics $diagnostics

if ($resultDependencies.Count -ne 0) {
    $dependencyHash = Invoke-LocalAction @commonParams @{
        type = 'set-dependency'
        parameters = @{
            dependencyBranches = $resultDependencies
            message = "Applied changes from 'simplify' audit"
        }
    }
    Assert-Diagnostics $diagnostics
}

# Finalize:
#    Push the new $dependencies

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
