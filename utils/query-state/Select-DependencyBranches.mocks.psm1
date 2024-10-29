Import-Module -Scope Local "$PSScriptRoot/Get-DependencyBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-AllDependencyBranches.mocks.psm1"

function Initialize-DependencyBranches([PSObject] $dependencyConfiguration) {
    Initialize-AllDependencyBranches $dependencyConfiguration
}
Export-ModuleMember -Function Initialize-DependencyBranches
