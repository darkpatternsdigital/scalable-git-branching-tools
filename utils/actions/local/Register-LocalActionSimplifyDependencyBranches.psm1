Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-SimplifyDependencyLocalAction {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]] $dependencyBranches,
        [Parameter()][AllowNull()] $overrideDependencies,
        [Parameter()][AllowNull()][string] $branchName,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    $dependencyBranches = $dependencyBranches | Where-Object { $_ }
    if ($dependencyBranches.Count -ne 0) {
        $dependencyBranches | Assert-ValidBranchName -diagnostics $diagnostics
    }
    if (Get-HasErrorDiagnostic $diagnostics) { return $null }

    if ($dependencyBranches.Count -eq 0) {
        $config = Get-Configuration
        if ($null -eq $config.defaultServiceLine) {
            Add-ErrorDiagnostic $diagnostics 'At least one dependency branch must be specified or the default service line must be set'
        }
        # default to service line if none provided and config has a service line
        return @( $config.defaultServiceLine )
    }

    $result = Compress-DependencyBranches $dependencyBranches -diagnostics:$diagnostics -overrideDependencies:$overrideDependencies -branchName:$branchName
    return $result
}

Export-ModuleMember -Function Invoke-SimplifyDependencyLocalAction
