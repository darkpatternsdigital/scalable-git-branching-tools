Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-DependencyBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

function Initialize-FetchDependencyBranch() {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        Invoke-MockGitModule -ModuleName 'Get-DependencyBranch' -gitCli "fetch $($config.remote) $($config.dependencyBranch)"
    }
}

Export-ModuleMember -Function Initialize-FetchDependencyBranch
