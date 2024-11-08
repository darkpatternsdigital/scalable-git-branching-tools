Describe 'local action "dependencies-updated"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../actions.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        Initialize-DependencyBranches @{
            'feature/FOO-456' = @("infra/add-services", "infra/refactor-api")
            'feature/FOO-123' = @("infra/add-services")
            'infra/add-services' = @("main")
            'infra/refactor-api' = @("main")
        }
    }

    function Add-StandardTests {
        Context 'without recursion' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
                $standardScript = ('{
                    "type": "dependencies-updated",
                    "parameters": {
                        "branches": ["feature/FOO-456", "feature/FOO-123"]
                    }
                }' | ConvertFrom-Json)
            }

            It 'reports when everything is up-to-date' {
                $mocks = Initialize-LocalActionDependenciesUpdated @('feature/FOO-456', 'feature/FOO-123')

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.noDependencies | Should -BeNullOrEmpty
                $outputs.needsUpdate.Keys | Should -BeNullOrEmpty
                $outputs.isUpdated | Should -Contain 'feature/FOO-456'
                $outputs.isUpdated | Should -Contain 'feature/FOO-123'
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }

            It 'reports when there are no dependencies' {
                $standardScript = ('{
                    "type": "dependencies-updated",
                    "parameters": {
                        "branches": ["unknown"]
                    }
                }' | ConvertFrom-Json)
                $mocks = Initialize-LocalActionDependenciesUpdated @()

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.noDependencies | Should -Contain 'unknown'
                $outputs.needsUpdate.Keys | Should -BeNullOrEmpty
                $outputs.isUpdated | Should -BeNullOrEmpty
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }

            It 'reports when everything is up-to-date' {
                $mocks = Initialize-LocalActionDependenciesUpdated @('feature/FOO-456', 'feature/FOO-123')

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.noDependencies | Should -BeNullOrEmpty
                $outputs.needsUpdate.Keys | Should -BeNullOrEmpty
                $outputs.isUpdated | Should -Contain 'feature/FOO-456'
                $outputs.isUpdated | Should -Contain 'feature/FOO-123'
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }

            It 'reports when a single branch is out of date' {
                $mocks = Initialize-LocalActionDependenciesUpdated @('feature/FOO-456') -outOfDate @{ 'feature/FOO-123' = @('infra/add-services') }

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.noDependencies | Should -BeNullOrEmpty
                $outputs.isUpdated | Should -Contain 'feature/FOO-456'
                $outputs.needsUpdate['feature/FOO-123'] | Should -Contain 'infra/add-services'
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }

            It 'reports when a multiple branches are out of date' {
                $mocks = Initialize-LocalActionDependenciesUpdated -outOfDate @{ 'feature/FOO-123' = @('infra/add-services'); 'feature/FOO-456' = @('infra/refactor-api') }

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.noDependencies | Should -BeNullOrEmpty
                $outputs.isUpdated | Should -BeNullOrEmpty
                $outputs.needsUpdate['feature/FOO-123'] | Should -Contain @('infra/add-services')
                $outputs.needsUpdate['feature/FOO-456'] | Should -Be @('infra/refactor-api')
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }
        }

        Context 'with recursion' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
                $standardScript = ('{
                    "type": "dependencies-updated",
                    "parameters": {
                        "branches": ["feature/FOO-456", "feature/FOO-123"],
                        "recurse": true
                    }
                }' | ConvertFrom-Json)
            }

            It 'reports when everything is up-to-date' {
                $mocks = Initialize-LocalActionDependenciesUpdated @('feature/FOO-456', 'feature/FOO-123') -recurse

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.needsUpdate.Keys | Should -BeNullOrEmpty
                $outputs.isUpdated | Should -Contain 'feature/FOO-456'
                $outputs.isUpdated | Should -Contain 'feature/FOO-123'
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }

            It 'reports when a single branch is out of date' {
                $mocks = Initialize-LocalActionDependenciesUpdated @('feature/FOO-456') -outOfDate @{ 'feature/FOO-123' = @('main') } -recurse

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.isUpdated | Should -Contain 'feature/FOO-456'
                $outputs.needsUpdate['feature/FOO-123'] | Should -Contain 'main'
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }

            It 'reports when a multiple branches are out of date' {
                $mocks = Initialize-LocalActionDependenciesUpdated -outOfDate @{ 'feature/FOO-123' = @('main'); 'feature/FOO-456' = @('infra/refactor-api') } -recurse

                $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                $outputs.isUpdated | Should -BeNullOrEmpty
                $outputs.needsUpdate['feature/FOO-123'] | Should -Contain @('main')
                $outputs.needsUpdate['feature/FOO-456'] | Should -Be @('infra/refactor-api')
                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
                Invoke-VerifyMock $mocks -Times 1
            }
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
        }

        Add-StandardTests

        It 'allows for overrides' {
            $script = ('{
                "type": "dependencies-updated",
                "parameters": {
                    "branches": ["feature/FOO-123"],
                    "overrideDependencies": {
                        "feature/FOO-123": ["main"]
                    }
                }
            }' | ConvertFrom-Json)

            $mocks = Initialize-LocalActionDependenciesUpdated @('feature/FOO-123') -recurse -overrideDependencies:@{
                "feature/FOO-123" = @("main")
            }

            $outputs = Invoke-LocalAction $script -diagnostics $fw.diagnostics

            $outputs.needsUpdate.Keys | Should -BeNullOrEmpty
            $outputs.isUpdated | Should -Contain 'feature/FOO-123'
            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
        }

        Add-StandardTests
    }
}
