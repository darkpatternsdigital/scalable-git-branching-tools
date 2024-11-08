Describe 'finalize action "set-branches"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-FinalizeAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionSetBranches.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    BeforeEach {
        $fw = Register-Framework -throwInsteadOfExit

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $output = $fw.assertDiagnosticOutput
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{
            "type": "set-branches",
            "parameters": {
                "branches": {
                    "$dependencies": "new-dependency-commitish",
                    "other": "other-commitish",
                    "another": "another-commitish",
                }
            }
        }' | ConvertFrom-Json)
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        [hashtable]$standardBranches = @{
            '$dependencies' = "new-dependency-commitish";
            other ="other-commitish";
            another ="another-commitish";
        }
    }

    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        It 'handles standard functionality' {
            Initialize-NoCurrentBranch
            $mocks = @(
                Initialize-AssertValidBranchName '$dependencies'
                Initialize-AssertValidBranchName 'other'
                Initialize-AssertValidBranchName 'another'
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch `$dependencies new-dependency-commitish -f"
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch other other-commitish -f"
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch another another-commitish -f"
            )

            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles standard functionality for a single branch' {
            $standardScript = ('{
                "type": "set-branches",
                "parameters": {
                    "branches": {
                        "other": "other-commitish"
                    }
                }
            }' | ConvertFrom-Json)
            Initialize-NoCurrentBranch
            $mocks = @(
                Initialize-AssertValidBranchName 'other'
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch other other-commitish -f"
            )

            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can execute a dry run' {
            Initialize-NoCurrentBranch
            $mocks = @(
                Initialize-AssertValidBranchName '$dependencies'
                Initialize-AssertValidBranchName 'other'
                Initialize-AssertValidBranchName 'another'
            )

            $dryRunCommands = Invoke-FinalizeAction $standardScript -diagnostics $diag -dryRun
            $diag | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

            $dryRunCommands | Should -Contain 'git branch $dependencies "new-dependency-commitish" -f'
            $dryRunCommands | Should -Contain 'git branch other "other-commitish" -f'
            $dryRunCommands | Should -Contain 'git branch another "another-commitish" -f'
        }

        It 'handles standard functionality using mocks' {
            Initialize-NoCurrentBranch
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports failures' {
            Initialize-NoCurrentBranch
            Initialize-FinalizeActionSetBranches $standardBranches -fail
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Get-HasErrorDiagnostic $diag | Should -Be $true
        }

        It 'can update the current branch' {
            Initialize-CurrentBranch 'another'
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'ensures the current branch, if updated, is clean' {
            Initialize-CurrentBranch 'another'
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches -currentBranchDirty
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  Git working directory is not clean.')
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'handles standard functionality' {
            $mocks = @(
                Initialize-AssertValidBranchName '$dependencies'
                Initialize-AssertValidBranchName 'other'
                Initialize-AssertValidBranchName 'another'
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "push origin --atomic new-dependency-commitish:refs/heads/`$dependencies another-commitish:refs/heads/another other-commitish:refs/heads/other"
            )

            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles standard functionality using mocks' {
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports failures' {
            Initialize-FinalizeActionSetBranches $standardBranches -fail
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Get-HasErrorDiagnostic $diag | Should -Be $true
        }

        It 'reports force-push' {
            $standardScript = ('{
                "type": "set-branches",
                "parameters": {
                    "force": true,
                    "branches": {
                        "$dependencies": "new-dependency-commitish",
                        "other": "other-commitish",
                        "another": "another-commitish",
                    }
                }
            }' | ConvertFrom-Json)
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches -force
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }
    }
    Context 'with remote where atomic is disabled' {
        BeforeEach {
            Initialize-ToolConfiguration -noAtomicPush
        }

        It 'handles standard functionality' {
            $mocks = @(
                Initialize-AssertValidBranchName '$dependencies'
                Initialize-AssertValidBranchName 'other'
                Initialize-AssertValidBranchName 'another'
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "push origin new-dependency-commitish:refs/heads/`$dependencies another-commitish:refs/heads/another other-commitish:refs/heads/other"
            )

            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles standard functionality using mocks' {
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports failures' {
            Initialize-FinalizeActionSetBranches $standardBranches -fail
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Get-HasErrorDiagnostic $diag | Should -Be $true
        }

        It 'supports force-push' {
            $standardScript = ('{
                "type": "set-branches",
                "parameters": {
                    "force": true,
                    "branches": {
                        "$dependencies": "new-dependency-commitish",
                        "other": "other-commitish",
                        "another": "another-commitish",
                    }
                }
            }' | ConvertFrom-Json)
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches -force
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
