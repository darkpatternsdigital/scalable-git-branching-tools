Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-DependenciesUpdatedLocalAction {
    param(
        [Parameter()][AllowEmptyCollection()][string[]] $branches,
        [Parameter()][AllowNull()] $overrideDependencies,
        [Parameter()][bool] $recurse = $false,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    $selectStandardParams = @{
        recurse = $recurse
        overrideDependencies = $overrideDependencies
    }
    $config = Get-Configuration
    $prefix = $config.remote ? "refs/remotes/$($config.remote)" : "refs/heads/"

    $needsUpdate = @{}
    $isUpdated = @()
    $noDependencies = @()
    foreach ($branch in $branches) {
        $dependencies = Select-DependencyBranches -branch $branch @selectStandardParams
        if (-not $dependencies) {
            $noDependencies += $branch
            continue
        }
        $target = "$prefix/$branch"
        [string[]]$fullyQualifiedDependencies = $dependencies | ForEach-Object { "$prefix/$_" }
        [string[]]$dependencyResults = Invoke-ProcessLogs "git for-each-ref --format=`"%(refname:lstrip=3) %(ahead-behind:$target)`" $fullyQualifiedDependencies" {
            git for-each-ref --format="%(refname:lstrip=3) %(ahead-behind:$target)" @fullyQualifiedDependencies
        } -allowSuccessOutput
        $outOfDate = ($dependencyResults | Where-Object { ($_ -split ' ')[1] -gt 0 } | ForEach-Object { ($_ -split ' ')[0] })
        if ($outOfDate.Count -gt 0) {
            $needsUpdate[$branch] = $outOfDate
        } else {
            $isUpdated += $branch
        }
    }

    return @{
        noDependencies = $noDependencies
        needsUpdate = $needsUpdate
        isUpdated = $isUpdated
    }
}

Export-ModuleMember -Function Invoke-DependenciesUpdatedLocalAction
