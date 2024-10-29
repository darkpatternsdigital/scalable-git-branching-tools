BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-DependencyBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-DependencyBranch.mocks.psm1"
}

Describe 'Get-DependencyBranch' {
    BeforeEach {
        Register-Framework
    }

    It 'computes the dependency tracking branch name' {
        Initialize-ToolConfiguration -dependencyBranchName 'my-dependency' -remote 'github'
        Get-DependencyBranch | Should -Be 'github/my-dependency'
    }
    It 'can handle no remote' {
        Initialize-ToolConfiguration -dependencyBranchName 'my-dependency' -noRemote
        Get-DependencyBranch | Should -Be 'my-dependency'
    }
    It 'fetches if requested' {
        Initialize-ToolConfiguration -dependencyBranchName 'my-dependency' -remote 'github'
        $mock = Initialize-FetchDependencyBranch

        Get-DependencyBranch -fetch | Should -Be 'github/my-dependency'
        Invoke-VerifyMock $mock -Times 1
    }
}
