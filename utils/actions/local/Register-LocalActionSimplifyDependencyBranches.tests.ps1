Describe 'local action "simplify-dependency"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSimplifyDependencyBranches.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    BeforeEach {
        $fw = Register-Framework -throwInsteadOfExit
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $output = $fw.assertDiagnosticOutput
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
    }

    It 'allows fallback to the default service line' {
        Initialize-ToolConfiguration -defaultServiceLine 'line/1.0'

        $result = Invoke-LocalAction @{
            type = 'simplify-dependency'
            parameters = @{
                dependencyBranches = @()
            }
        } -diagnostics $diag
        try { Assert-Diagnostics $diag } catch { }
        $output | Should -BeNullOrEmpty
        Should -ActualValue $result -Be @('line/1.0')
    }

    It 'allows mocked simplification' {
        Initialize-LocalActionSimplifyDependencyBranchesSuccess -from @('foo', 'bar') -to @('foo')

        $result = Invoke-LocalAction @{
            type = 'simplify-dependency'
            parameters = @{
                dependencyBranches = @('foo', 'bar')
            }
        } -diagnostics $diag
        try { Assert-Diagnostics $diag } catch { }
        $output | Should -BeNullOrEmpty
        Should -ActualValue $result -Be @('foo')
    }
}
