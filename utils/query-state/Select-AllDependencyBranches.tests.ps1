BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-AllDependencyBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-AllDependencyBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
}

Describe 'Select-AllDependencyBranches' {
    BeforeEach {
        Register-Framework
    }

    Describe 'simple structure' {
        BeforeEach {
            Initialize-ToolConfiguration -dependencyBranchName 'my-dependency'
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $mocks = Initialize-AllDependencyBranches @{
                'my-branch' = @("feature/FOO-123", "feature/XYZ-1-services")
            }
        }

        It 'finds dependency branches from git' {
            (Select-AllDependencyBranches)['my-branch'] | Should -Be @( 'feature/FOO-123', 'feature/XYZ-1-services' )
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'provides $null for missing branches' {
            (Select-AllDependencyBranches)['not/a/branch'] | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'only runs once, even if called multiple times' {
            Select-AllDependencyBranches
            Select-AllDependencyBranches
            Invoke-VerifyMock $mocks -Times 1
            {
                Invoke-ProcessLogs 'testing' { Invoke-VerifyMock $mocks -Times 2 }
            } | Should -Throw
        }

        It 'runs twice if specified' {
            Select-AllDependencyBranches
            Select-AllDependencyBranches -refresh
            Invoke-VerifyMock $mocks -Times 2
        }
    }

    Describe 'complex structures' {
        BeforeEach {
            Initialize-ToolConfiguration
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $mocks = Initialize-AllDependencyBranches @{
                'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-123' = @("line/1.0")
                'feature/XYZ-1-services' = @("infra/some-service")
                'infra/some-service' = @("line/1.0")
            }
        }

        It 'handles deep folders' {
            (Select-AllDependencyBranches)['feature/FOO-123'] | Should -Be @("line/1.0")
            (Select-AllDependencyBranches)['feature/XYZ-1-services'] | Should -Be @("infra/some-service")
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Describe 'at an alternate commit' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'handles deep folders' {
            $mocks = Initialize-AllDependencyBranches @{
                'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/XYZ-1-services' = @("infra/some-service")
                'infra/some-service' = @("line/1.0")
            }
            $overrideDependencies = @{
                'feature/FOO-123' = @("line/1.0")
                'infra/some-service' = @('main')
            };

            (Select-AllDependencyBranches -overrideDependencies $overrideDependencies)['feature/FOO-123'] | Should -Be @("line/1.0")
            (Select-AllDependencyBranches -overrideDependencies $overrideDependencies)['feature/XYZ-1-services'] | Should -Be @("infra/some-service")
            (Select-AllDependencyBranches -overrideDependencies $overrideDependencies)['infra/some-service'] | Should -Be @("main")
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
