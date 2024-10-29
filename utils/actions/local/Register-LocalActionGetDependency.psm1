Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-GetDependencyLocalAction {
    param(
        [Parameter(Mandatory)][string] $target,
        [Parameter()][AllowNull()] $overrideDependencies,
        [switch] $recurse,
        [switch] $includeRemote,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    [string[]]$result = Select-DependencyBranches -branchName $target -recurse:$recurse -includeRemote:$includeRemote -overrideDependencies:$overrideDependencies

    return $result
}

Export-ModuleMember -Function Invoke-GetDependencyLocalAction
