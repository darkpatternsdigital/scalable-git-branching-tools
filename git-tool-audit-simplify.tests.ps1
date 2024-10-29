Describe 'git-tool-audit-simplify' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $initialCommits = @{
            'rc/2022-07-14' = 'rc/2022-07-14-commitish'
            'main' = 'main-commitish'
            'feature/FOO-123' = 'feature/FOO-123-commitish'
            'feature/XYZ-1-services' = 'feature/XYZ-1-services-commitish'
            'feature/FOO-124-comment' = 'feature/FOO-124-comment-commitish'
            'feature/FOO-124_FOO-125' = 'feature/FOO-124_FOO-125-commitish'
            'feature/FOO-76' = 'feature/FOO-76-commitish'
            'integrate/FOO-125_XYZ-1' = 'integrate/FOO-125_XYZ-1-commitish'
        }

        function Initialize-ValidDependantBranchNames {
            $dependencies = Select-AllDependencyBranches
            [string[]]$entries = @()
            foreach ($key in $dependencies.Keys) {
                foreach ($dependants in $dependencies[$key]) {
                    if ($dependants -notin $entries) {
                        [string[]]$entries = $entries + @($dependants)
                        Initialize-AssertValidBranchName $dependants
                    }
                }
            }
        }

    }

    function Add-StandardTests {
        It 'handles standard functionality' {
            Initialize-AllDependencyBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment", "main")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1", "feature/FOO-124-comment")
            } -initialCommits $initialCommits
            Initialize-ValidDependantBranchNames
            Initialize-LocalActionSetDependency @{
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1")
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
            } "Applied changes from 'simplify' audit" 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }

            & $PSScriptRoot/git-tool-audit-simplify.ps1
            $fw.assertDiagnosticOutput.Count | Should -Be 2
            $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'main' from dependency branches of 'feature/FOO-124_FOO-125'; it is redundant via the following: feature/FOO-124-comment"
            $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'feature/FOO-124-comment' from dependency branches of 'rc/2022-07-14'; it is redundant via the following: integrate/FOO-125_XYZ-1"
        }

        It 'can issue a dry run' {
            Initialize-AllDependencyBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment", "main")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1", "feature/FOO-124-comment")
            } -initialCommits $initialCommits
            Initialize-ValidDependantBranchNames
            Initialize-LocalActionSetDependency @{
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1")
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
            } "Applied changes from 'simplify' audit" 'new-commit'
            Initialize-AssertValidBranchName "`$dependencies"

            & $PSScriptRoot/git-tool-audit-simplify.ps1 -dryRun
            $fw.assertDiagnosticOutput.Count | Should -Be 2
            $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'main' from dependency branches of 'feature/FOO-124_FOO-125'; it is redundant via the following: feature/FOO-124-comment"
            $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'feature/FOO-124-comment' from dependency branches of 'rc/2022-07-14'; it is redundant via the following: integrate/FOO-125_XYZ-1"
        }

        It 'does nothing if no changes are needed' {
            Initialize-AllDependencyBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1")
            } -initialCommits $initialCommits
            Initialize-ValidDependantBranchNames

            & $PSScriptRoot/git-tool-audit-simplify.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-NoCurrentBranch
        }
        Add-StandardTests
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-NoCurrentBranch
        }
        Add-StandardTests
    }
}
