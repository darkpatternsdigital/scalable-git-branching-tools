Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-GetDependantLocalAction {
    param(
        [Parameter(Mandatory)][string] $target,
        [Parameter()][AllowNull()] $overrideDependencies,
        [switch] $recurse,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    [string[]]$result = Select-DependantBranches -branchName $target -recurse:$recurse -overrideDependencies:$overrideDependencies

    return $result
}

Export-ModuleMember -Function Invoke-GetDependantLocalAction
