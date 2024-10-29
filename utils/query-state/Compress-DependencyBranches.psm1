Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-DependencyBranches.psm1"

function Compress-DependencyBranches(
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $originalDependency,
    [Parameter()][AllowNull()] $overrideDependencies,
    [Parameter()][AllowNull()][string] $branchName,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $allDependency = $originalDependency | ConvertTo-HashMap -getValue {
        return ([string[]](Select-DependencyBranches $_ -recurse -overrideDependencies:$overrideDependencies))
    }
    $resultDependency = [System.Collections.ArrayList]$originalDependency
    for ($i = 0; $i -lt $resultDependency.Count; $i++) {
        $branch = $resultDependency[$i]
        $alreadyContainedBy = ($resultDependency | Where-Object { $_ -ne $branch -AND $allDependency[$_] -contains $branch })
        if ($alreadyContainedBy -ne $nil) {
            if (-not $branchName) {
                Add-WarningDiagnostic $diagnostics "Removing '$branch' from branches; it is redundant via the following: $alreadyContainedBy"
            } else {
                Add-WarningDiagnostic $diagnostics "Removing '$branch' from dependency branches of '$branchName'; it is redundant via the following: $alreadyContainedBy"
            }
            # $branch is in the recursive dependency of at least one other branch
            $resultDependency.Remove($branch)
            $i--
        }
    }
    return [string[]]$resultDependency
}

Export-ModuleMember -Function Compress-DependencyBranches
