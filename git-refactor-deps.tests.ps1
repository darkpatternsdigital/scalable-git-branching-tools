Describe 'git-refactor-deps' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote

        # These are all valid branch names; tehy don't need to be defined each time:
        Initialize-AssertValidBranchName 'integrate/FOO-100_XYZ-1'
        Initialize-AssertValidBranchName 'integrate/FOO-123_XYZ-1'
        Initialize-AssertValidBranchName 'feature/FOO-100'
        Initialize-AssertValidBranchName 'feature/FOO-123'
        Initialize-AssertValidBranchName 'feature/FOO-124'
        Initialize-AssertValidBranchName 'feature/FOO-125'
        Initialize-AssertValidBranchName 'feature/XYZ-1-services'
        Initialize-AssertValidBranchName 'infra/shared'
        Initialize-AssertValidBranchName 'infra/other'
        Initialize-AssertValidBranchName 'main'
        Initialize-AssertValidBranchName 'bad-recursive-branch-1'
        Initialize-AssertValidBranchName 'bad-recursive-branch-2'
    }

    It 'prevents running if neither remove nor rename are provided' {
        { & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-123' -target 'main' } | Should -Throw

        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  One of -rename, -remove, or -combine must be specfied.'
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'prevents running if both remove and rename are provided' {
        { & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-123' -target 'main' -remove -rename } | Should -Throw

        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  Only one of -rename, -remove, and -combine may be specified.'
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can consolidate a released branch (feature/FOO-123) into main' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'feature/FOO-123' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-LocalActionSetDependency @{
                'feature/FOO-123' = $null
                'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-123' -target 'main' -remove

        $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'main' from dependency branches of 'integrate/FOO-123_XYZ-1'; it is redundant via the following: feature/XYZ-1-services"
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can consolidate an integration branch (integrate/FOO-123_XYZ-1) into its remaining dependency' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-LocalActionSetDependency @{
                'feature/FOO-124' = @("feature/XYZ-1-services")
                'rc/1.1.0' = @("feature/XYZ-1-services")
                'integrate/FOO-123_XYZ-1' = @()
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-deps.ps1 -source 'integrate/FOO-123_XYZ-1' -target 'feature/XYZ-1-services' -remove

        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can rename an incorrectly named branch' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-100_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-100_XYZ-1")
                'feature/FOO-123' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-100_XYZ-1")
            }
            Initialize-LocalActionSetDependency @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'integrate/FOO-100_XYZ-1' = @()
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-deps.ps1 -source 'integrate/FOO-100_XYZ-1' -target 'integrate/FOO-123_XYZ-1' -rename

        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can rename an incorrectly named branch already used correctly sometimes' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-100", "feature/XYZ-1-services")
                'feature/FOO-124' = @("feature/FOO-123", "main")
                'feature/FOO-100' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-LocalActionSetDependency @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-100' = @()
                'feature/FOO-123' = @('main')
                'feature/FOO-124' = @("feature/FOO-123")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-100' -target 'feature/FOO-123' -rename

        $fw.assertDiagnosticOutput | Should -Be @(
            "WARN: Removing 'main' from dependency branches of 'feature/FOO-124'; it is redundant via the following: feature/FOO-123"
        )
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can replace an incorrectly named branch that already has configurations' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-100", "feature/XYZ-1-services")
                'feature/FOO-124' = @("feature/FOO-123", "infra/shared")
                'feature/FOO-123' = @("main", 'infra/other')
                'feature/FOO-100' = @("infra/shared")
                'infra/shared' = @('main')
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-LocalActionSetDependency @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-100' = @()
                'feature/FOO-123' = @('infra/shared')
                'feature/FOO-124' = @("feature/FOO-123")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-100' -target 'feature/FOO-123' -rename

        $fw.assertDiagnosticOutput | Should -Be @(
            "WARN: Removing 'infra/shared' from dependency branches of 'feature/FOO-124'; it is redundant via the following: feature/FOO-123"
        )
        Invoke-VerifyMock $mocks -Times 1
    }
    It 'can combine an incorrectly named branch that already has configurations' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-100", "feature/XYZ-1-services")
                'feature/FOO-124' = @("feature/FOO-123", "infra/shared")
                'feature/FOO-123' = @("main", 'infra/other')
                'feature/FOO-100' = @("infra/shared")
                'infra/shared' = @('main')
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-LocalActionSetDependency @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-100' = @()
                'feature/FOO-123' = @('infra/other', 'infra/shared')
                'feature/FOO-124' = @("feature/FOO-123")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '$dependencies' = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-100' -target 'feature/FOO-123' -combine

        $fw.assertDiagnosticOutput | Should -Be @(
            "WARN: Removing 'main' from dependency branches of 'feature/FOO-123'; it is redundant via the following: infra/shared"
            "WARN: Removing 'infra/shared' from dependency branches of 'feature/FOO-124'; it is redundant via the following: feature/FOO-123"
        )
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'errors if no changes are made' {
        $mocks = @(
            Initialize-AllDependencyBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
        )

        { & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-123' -target 'main' -remove } | Should -Throw

        $fw.assertDiagnosticOutput | Should -Contain "ERR:  No changes were found."
        Invoke-VerifyMock $mocks -Times 1
    }

    Describe 'Advanced use-cases' {
        It 'simplifies other dependants branches' {
            $mocks = @(
                Initialize-AllDependencyBranches @{
                    'feature/FOO-125' = @("feature/FOO-124", "main")
                    'feature/FOO-124' = @("feature/FOO-123")
                }
                Initialize-LocalActionSetDependency @{
                    'feature/FOO-124' = @("main")
                    'feature/FOO-125' = @("feature/FOO-124")
                } -commitish 'new-commit'
                Initialize-FinalizeActionSetBranches @{
                    '$dependencies' = 'new-commit'
                }
            )

            & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-123' -target 'main' -remove

            $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'main' from dependency branches of 'feature/FOO-125'; it is redundant via the following: feature/FOO-124"
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can be used to fix recursive branches' {
            $mocks = @(
                Initialize-AllDependencyBranches @{
                    'bad-recursive-branch-1' = @('bad-recursive-branch-2', 'main')
                    'bad-recursive-branch-2' = @('bad-recursive-branch-1')
                }
                Initialize-LocalActionSetDependency @{
                    'bad-recursive-branch-1' = @("main")
                    'bad-recursive-branch-2' = @()
                } -commitish 'new-commit'
                Initialize-FinalizeActionSetBranches @{
                    '$dependencies' = 'new-commit'
                }
            )

            & $PSScriptRoot/git-refactor-deps.ps1 -source 'bad-recursive-branch-2' -target 'bad-recursive-branch-1' -remove

            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can be used to fix recursive branches via combine' {
            $mocks = @(
                Initialize-AllDependencyBranches @{
                    'bad-recursive-branch-1' = @('bad-recursive-branch-2', 'main')
                    'bad-recursive-branch-2' = @('bad-recursive-branch-1')
                }
                Initialize-LocalActionSetDependency @{
                    'bad-recursive-branch-1' = @("main")
                    'bad-recursive-branch-2' = @()
                } -commitish 'new-commit'
                Initialize-FinalizeActionSetBranches @{
                    '$dependencies' = 'new-commit'
                }
            )

            & $PSScriptRoot/git-refactor-deps.ps1 -source 'bad-recursive-branch-2' -target 'bad-recursive-branch-1' -combine

            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'does not create repeat dependencies' {
            $mocks = @(
                Initialize-AllDependencyBranches @{
                    'feature/FOO-123' = @("main")
                    'feature/FOO-124' = @("feature/FOO-123", "main")
                }
                Initialize-LocalActionSetDependency @{
                    'feature/FOO-123' = $null
                    'feature/FOO-124' = @("main")
                } -commitish 'new-commit'
                Initialize-FinalizeActionSetBranches @{
                    '$dependencies' = 'new-commit'
                }
            )

            & $PSScriptRoot/git-refactor-deps.ps1 -source 'feature/FOO-123' -target 'main' -remove

            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
