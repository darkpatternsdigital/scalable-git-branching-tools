Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-GetAllDependenciesLocalAction {
    param(
        [Parameter()][AllowNull()] $overrideDependencies,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    return Select-AllDependencyBranches -overrideDependencies:$overrideDependencies
}

Export-ModuleMember -Function Invoke-GetAllDependenciesLocalAction
