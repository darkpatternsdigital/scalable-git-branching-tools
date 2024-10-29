BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-DependantBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-AllDependencyBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
}

Describe 'Select-DependantBranches' {
    BeforeEach {
        Register-Framework
        Initialize-ToolConfiguration

        Initialize-AllDependencyBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("feature/FOO-123")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")

            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }
    }

    It 'finds dependants branches' {
        $results = Select-DependantBranches 'main'
        $results.Length | Should -Be 2
        $results | Should -Contain 'feature/FOO-123'
        $results | Should -Contain 'feature/XYZ-1-services'
    }

    It 'allows some dependants to be excluded' {
        $results = Select-DependantBranches 'main' -exclude @('feature/FOO-123')
        $results | Should -Be @( 'feature/XYZ-1-services' )
    }

    It 'finds recursive dependants branches' {
        $results = Select-DependantBranches 'main' -recurse
        $results.Length | Should -Be 5
        $results | Should -Contain 'feature/FOO-123'
        $results | Should -Contain 'feature/XYZ-1-services'
        $results | Should -Contain 'feature/FOO-124'
        $results | Should -Contain 'integrate/FOO-123_XYZ-1'
        $results | Should -Contain 'rc/1.1.0'
    }

    It 'allows some to be excluded even through ancestors' {
        $results = Select-DependantBranches 'main' -recurse -exclude @('rc/1.1.0')
        $results.Length | Should -Be 4
        $results | Should -Contain 'feature/FOO-123'
        $results | Should -Contain 'feature/XYZ-1-services'
        $results | Should -Contain 'feature/FOO-124'
        $results | Should -Contain 'integrate/FOO-123_XYZ-1'
    }

    It 'handles (invalid) recursiveness without failing' {
        $results = Select-DependantBranches bad-recursive-branch-1 -recurse
        $results | Should -Be @( 'bad-recursive-branch-2' )
    }

    It 'allows overrides' {
        $results = Select-DependantBranches infra/next -overrideDependencies @{ 'feature/FOO-123' = 'infra/next' }
        $results | Should -Be @( 'feature/FOO-123' )
    }
}
