Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

function Get-DependencyBranch(
    [switch] $fetch
) {
    $config = Get-Configuration
    $dependencyBranch = $config.remote -eq $nil ? $config.dependencyBranch : "$($config.remote)/$($config.dependencyBranch)"

    if ($config.remote -ne $nil -AND $fetch) {
        git fetch $config.remote $config.dependencyBranch 2> $nil
    }

    return $dependencyBranch
}
Export-ModuleMember -Function Get-DependencyBranch
