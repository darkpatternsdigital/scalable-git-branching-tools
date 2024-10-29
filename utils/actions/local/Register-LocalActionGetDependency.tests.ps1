Describe 'local action "get-dependency"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionGetDependency.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{
            "type": "get-dependency",
            "parameters": {
                "target": "my-branch"
            }
        }' | ConvertFrom-Json)
    }

    function Initialize-StandardTests {
        It 'gets the configured dependency branches' {
            Initialize-DependencyBranches @{
                'my-branch' = @('main')
            }

            $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $results | Should -Be @('main')
        }

        It 'gets all configured dependency branches' {
            Initialize-DependencyBranches @{
                'my-branch' = @('feature-base', 'infra/refactor')
            }

            $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $results | Should -Be @('feature-base', 'infra/refactor')
        }

        It 'gets an empty array if no configuration exists' {
            Initialize-DependencyBranches @{
                'my-other-branch' = @('feature-base', 'infra/refactor')
            }

            $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $results | Should -Be @()
        }
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        Initialize-StandardTests


        It 'gets dependency branches with overrides' {
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-124' = @("feature/FOO-123")
                'feature/FOO-123' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")

                'bad-recursive-branch-1' = @('bad-recursive-branch-2')
                'bad-recursive-branch-2' = @('bad-recursive-branch-1')
            }
            [string[]]$result = Invoke-LocalAction ('{
                "type": "get-dependency",
                "parameters": {
                    "target": "infra/new",
                    "overrideDependencies": {
                        "feature/FOO-123": "infra/new",
                        "infra/new": "main"
                    }
                }
            }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $result.Length | Should -Be 1
            $result | Should -Contain 'main'
        }
    }

    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        Initialize-StandardTests
    }
}
