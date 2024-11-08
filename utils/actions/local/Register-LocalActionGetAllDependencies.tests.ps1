Describe 'local action "get-all-dependencies"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../actions.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    BeforeEach {
        Initialize-ToolConfiguration

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{
            "type": "get-all-dependencies",
            "parameters": {
            }
        }' | ConvertFrom-Json)
    }

    It 'returns all dependency data' {
        Initialize-AllDependencyBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("feature/FOO-123")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")

            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty

        $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        $results.Keys | Should -Contain 'integrate/FOO-123_XYZ-1'
        $results.Keys | Should -Contain 'feature/FOO-124'
        $results.Keys | Should -Contain 'feature/FOO-123'
        $results.Keys | Should -Contain 'feature/XYZ-1-services'
        $results.Keys | Should -Contain 'rc/1.1.0'
        $results.Keys | Should -Contain 'bad-recursive-branch-1'
        $results.Keys | Should -Contain 'bad-recursive-branch-2'
        $results['rc/1.1.0'] | Should -Contain "feature/FOO-123"
        $results['rc/1.1.0'] | Should -Contain "feature/XYZ-1-services"
    }

    It 'can override dependencies' {
        Initialize-AllDependencyBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("feature/FOO-123")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")

            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }
        $script = ('{
            "type": "get-all-dependencies",
            "parameters": {
                "overrideDependencies": {
                    "feature/FOO-123": "infra/new",
                    "infra/new": "main"
                }
            }
        }' | ConvertFrom-Json)

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty

        $results = Invoke-LocalAction $script -diagnostics $fw.diagnostics

        $results.Keys | Should -Contain 'integrate/FOO-123_XYZ-1'
        $results.Keys | Should -Contain 'feature/FOO-124'
        $results.Keys | Should -Contain 'feature/FOO-123'
        $results.Keys | Should -Contain 'feature/XYZ-1-services'
        $results.Keys | Should -Contain 'rc/1.1.0'
        $results.Keys | Should -Contain 'bad-recursive-branch-1'
        $results.Keys | Should -Contain 'bad-recursive-branch-2'
        $results.Keys | Should -Contain 'infra/new'
        $results['rc/1.1.0'] | Should -Contain "feature/FOO-123"
        $results['rc/1.1.0'] | Should -Contain "feature/XYZ-1-services"
        $results['feature/FOO-123'] | Should -Contain "infra/new"
        $results['feature/FOO-123'] | Should -Not -Contain "main"
        $results['infra/new'] | Should -Contain "main"
    }
}
