BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

    function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
        return Invoke-MockGitModule -ModuleName 'Configuration' @PSBoundParameters
    }
}

Describe 'Get-Configuration' {

    It 'Defaults values' {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote'
        Invoke-MockGit 'config scaled-git.defaultServiceLine'
        Invoke-MockGit 'rev-parse --verify main -q' { 'some-hash' }
        Invoke-MockGit 'config scaled-git.dependencyBranch'
        Invoke-MockGit 'config scaled-git.atomicPushEnabled'

        Get-Configuration | Assert-ShouldBeObject @{ remote = $null; dependencyBranch = '$dependencies'; defaultServiceLine = 'main'; atomicPushEnabled = $true }
    }

    It 'Defaults values with no main branch' {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote'
        Invoke-MockGit 'config scaled-git.defaultServiceLine'
        Invoke-MockGit 'rev-parse --verify main -q' { $global:LASTEXITCODE = 128 }
        Invoke-MockGit 'config scaled-git.dependencyBranch'
        Invoke-MockGit 'config scaled-git.atomicPushEnabled'

        Get-Configuration | Assert-ShouldBeObject @{ remote = $null; dependencyBranch = '$dependencies'; defaultServiceLine = $null; atomicPushEnabled = $true }
    }

    It 'Defaults values with a remote main branch' {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote' { 'origin' }
        Invoke-MockGit 'config scaled-git.defaultServiceLine'
        Invoke-MockGit 'rev-parse --verify origin/main -q' { 'some-hash'}
        Invoke-MockGit 'config scaled-git.dependencyBranch'
        Invoke-MockGit 'config scaled-git.atomicPushEnabled'

        Get-Configuration | Assert-ShouldBeObject @{ remote = 'origin'; dependencyBranch = '$dependencies'; defaultServiceLine = 'main'; atomicPushEnabled = $true }
    }

    It 'Overrides defaults' {
        Invoke-MockGit 'config scaled-git.remote' { 'github' }
        Invoke-MockGit 'config scaled-git.dependencyBranch' { 'dependency-config' }
        Invoke-MockGit 'config scaled-git.defaultServiceLine' { 'trunk' }
        Invoke-MockGit 'config scaled-git.atomicPushEnabled' { $false }

        Get-Configuration | Assert-ShouldBeObject @{ remote = 'github'; dependencyBranch = 'dependency-config'; defaultServiceLine = 'trunk'; atomicPushEnabled = $false }
    }
}
