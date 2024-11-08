BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
}

Describe 'git-pull-deps' {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    function Add-StandardTests {
        It 'fails if no branch is checked out and none is specified' {
            $mocks = @(
                Initialize-NoCurrentBranch
            )

            { & ./git-pull-deps.ps1 } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Contain "ERR:  No branch name was provided"
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'fails if the working directory is not clean' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-CurrentBranch 'feature/FOO-123'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/FOO-123'
                Initialize-LocalActionMergeBranchesSuccess `
                    -dependencyBranches @('infra/add-services') -resultCommitish 'result-commitish' `
                    -source 'feature/FOO-123' `
                    -mergeMessageTemplate "Merge '{}' to feature/FOO-123"
                Initialize-FinalizeActionSetBranches @{
                    'feature/FOO-123' = 'result-commitish'
                } -currentBranchDirty
                Initialize-FinalizeActionTrackSuccess @('feature/FOO-123') -currentBranchDirty
            )

            { & $PSScriptRoot/git-pull-deps.ps1 } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  Git working directory is not clean.')
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'merges all dependency branches for the current branch' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/FOO-456'
                Initialize-LocalActionMergeBranchesSuccess `
                    -dependencyBranches @('infra/add-services', 'infra/refactor-api') -resultCommitish 'result-commitish' `
                    -source 'feature/FOO-456' `
                    -mergeMessageTemplate "Merge '{}' to feature/FOO-456"
                Initialize-FinalizeActionSetBranches @{
                    'feature/FOO-456' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('feature/FOO-456')
            )

            & $PSScriptRoot/git-pull-deps.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It "merges dependency branches for the specified branch when an dependency branch cannot be merged" {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/FOO-456'
                Initialize-LocalActionMergeBranchesSuccess `
                    -dependencyBranches @('infra/add-services', 'infra/refactor-api') -resultCommitish 'result-commitish' `
                    -failedBranches 'infra/refactor-api' `
                    -source 'feature/FOO-456' `
                    -mergeMessageTemplate "Merge '{}' to feature/FOO-456"
                Initialize-FinalizeActionSetBranches @{
                    'feature/FOO-456' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('feature/FOO-456')
            )

            & $PSScriptRoot/git-pull-deps.ps1
            $fw.assertDiagnosticOutput | Should -Be @(
                "WARN: feature/FOO-456 has incoming conflicts from infra/refactor-api. Resolve them before continuing."
            )
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'uses the branch specified, recursively, and passes if there are no changes' {
            $remote = $(Get-Configuration).remote
            $remotePrefix = $remote ? "$remote/" : ""
            $initialCommits = @{
                "$($remotePrefix)main" = "$($remotePrefix)main-commitish"
                "$($remotePrefix)feature/PS-1" = "$($remotePrefix)feature/PS-1-commitish"
                "$($remotePrefix)infra/ts-update" = "$($remotePrefix)infra/ts-update-commitish"
                "$($remotePrefix)infra/build-improvements" = "$($remotePrefix)infra/build-improvements-commitish"
                "$($remotePrefix)feature/PS-2" = "$($remotePrefix)feature/PS-2-commitish"
            }

            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-DependencyBranches @{
                    'feature/PS-2' = @('feature/PS-1','infra/build-improvements')
                    'feature/PS-1' = @('infra/ts-update')
                    'infra/build-improvements' = @('infra/ts-update')
                    'infra/ts-update' = @('main')
                }
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-1'
                Initialize-LocalActionAssertPushedSuccess 'infra/build-improvements'
                Initialize-LocalActionAssertPushedSuccess 'infra/ts-update'
                Initialize-LocalActionAssertPushedSuccess 'main'

                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('main') `
                    -noChangeBranches @('main') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/ts-update"] `
                    -source 'infra/ts-update' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to infra/ts-update"
                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('infra/ts-update') `
                    -noChangeBranches @('infra/ts-update') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/build-improvements"] `
                    -source 'infra/build-improvements' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to infra/build-improvements"
                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('infra/ts-update') `
                    -noChangeBranches @('infra/ts-update') `
                    -resultCommitish $initialCommits["$($remotePrefix)feature/PS-1"] `
                    -source 'feature/PS-1' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to feature/PS-1"
                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('feature/PS-1','infra/build-improvements') `
                    -noChangeBranches @('feature/PS-1','infra/build-improvements') `
                    -resultCommitish $initialCommits["$($remotePrefix)feature/PS-2"] `
                    -source 'feature/PS-2' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to feature/PS-2"
            )

            & $PSScriptRoot/git-pull-deps.ps1 -target feature/PS-2 -recurse
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'uses the branch specified, recursively, and propagates merged changes' {
            $remote = $(Get-Configuration).remote
            $remotePrefix = $remote ? "$remote/" : ""
            $initialCommits = @{
                "$($remotePrefix)main" = "$($remotePrefix)main-commitish"
                "$($remotePrefix)feature/PS-1" = "$($remotePrefix)feature/PS-1-commitish"
                "$($remotePrefix)infra/build-improvements" = "$($remotePrefix)infra/build-improvements-commitish"
                "$($remotePrefix)feature/PS-2" = "$($remotePrefix)feature/PS-2-commitish"
            }
            $updatedCommits = @{
                "$($remotePrefix)feature/PS-1" = "PS-1-updated"
                "$($remotePrefix)feature/PS-2" = "PS-2-updated"
            }

            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-DependencyBranches @{
                    'feature/PS-2' = @('feature/PS-1','infra/build-improvements')
                    'feature/PS-1' = @('main')
                    'infra/build-improvements' = @('main')
                }
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-1'
                Initialize-LocalActionAssertPushedSuccess 'infra/build-improvements'
                Initialize-LocalActionAssertPushedSuccess 'main'

                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('main') `
                    -successfulBranches @('main') `
                    -resultCommitish $updatedCommits["$($remotePrefix)feature/PS-1"] `
                    -source 'feature/PS-1' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to feature/PS-1"
                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('main') `
                    -noChangeBranches @('main') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/build-improvements"] `
                    -source 'infra/build-improvements' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to infra/build-improvements"
                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('feature/PS-1','infra/build-improvements') `
                    -successfulBranches @('feature/PS-1') `
                    -noChangeBranches @('infra/build-improvements') `
                    -resultCommitish $updatedCommits["$($remotePrefix)feature/PS-2"] `
                    -source 'feature/PS-2' `
                    -initialCommits  @{
                        "$($remotePrefix)feature/PS-1" = $updatedCommits["$($remotePrefix)feature/PS-1"]
                        "$($remotePrefix)infra/build-improvements" = $initialCommits["$($remotePrefix)infra/build-improvements"]
                        "$($remotePrefix)feature/PS-2" = $initialCommits["$($remotePrefix)feature/PS-2"]
                    } `
                    -skipRevParse @(
                        # feature/PS-1 was updated in a previous merge; we should automatically use that instead
                        "$($remotePrefix)feature/PS-1"
                    ) `
                    -mergeMessageTemplate "Merge '{}' to feature/PS-2"

                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-FinalizeActionSetBranches @{
                    'feature/PS-1' = $updatedCommits["$($remotePrefix)feature/PS-1"]
                    'feature/PS-2' = $updatedCommits["$($remotePrefix)feature/PS-2"]
                }
                Initialize-FinalizeActionTrackSuccess @('infra/build-improvements', 'feature/PS-1','feature/PS-2')
            )

            & $PSScriptRoot/git-pull-deps.ps1 -target feature/PS-2 -recurse
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'uses the branch specified, recursively, and fails if an dependency merge fails' {
            # Fails merging 'main' into 'infra/build-improvements'
            $remote = $(Get-Configuration).remote
            $remotePrefix = $remote ? "$remote/" : ""
            $initialCommits = @{
                "$($remotePrefix)main" = "$($remotePrefix)main-commitish"
                "$($remotePrefix)feature/PS-1" = "$($remotePrefix)feature/PS-1-commitish"
                "$($remotePrefix)infra/build-improvements" = "$($remotePrefix)infra/build-improvements-commitish"
                "$($remotePrefix)feature/PS-2" = "$($remotePrefix)feature/PS-2-commitish"
            }
            $updatedCommits = @{
                "$($remotePrefix)feature/PS-1" = "PS-1-updated"
                "$($remotePrefix)feature/PS-2" = "PS-2-updated"
            }

            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-DependencyBranches @{
                    'feature/PS-2' = @('feature/PS-1','infra/build-improvements')
                    'feature/PS-1' = @('main')
                    'infra/build-improvements' = @('main')
                }
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-1'
                Initialize-LocalActionAssertPushedSuccess 'infra/build-improvements'
                Initialize-LocalActionAssertPushedSuccess 'main'

                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('main') `
                    -successfulBranches @('main') `
                    -resultCommitish $updatedCommits["$($remotePrefix)feature/PS-1"] `
                    -source 'feature/PS-1' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to feature/PS-1"
                Initialize-LocalActionMergeBranches `
                    -dependencyBranches @('main') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/build-improvements"] `
                    -source 'infra/build-improvements' `
                    -initialCommits $initialCommits `
                    -mergeMessageTemplate "Merge '{}' to infra/build-improvements"
            )

            { & $PSScriptRoot/git-pull-deps.ps1 -target feature/PS-2 -recurse } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Contain 'ERR:  infra/build-improvements has incoming conflicts from main. Resolve them before continuing.'
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-DependencyBranches @{
                'feature/FOO-456' = @("infra/add-services", "infra/refactor-api")
                'feature/FOO-123' = @("infra/add-services")
                'infra/add-services' = @("main")
                'infra/refactor-api' = @("main")
            }
        }

        Add-StandardTests

        It 'ensures the remote is up-to-date' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedAhead 'feature/FOO-456'
            )

            { & $PSScriptRoot/git-pull-deps.ps1 } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  The local branch for feature/FOO-456 has changes that are not pushed to the remote')
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'ensures the remote is up-to-date with the specified branch' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedAhead 'feature/FOO-456'
            )

            { & $PSScriptRoot/git-pull-deps.ps1 'feature/FOO-456' } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  The local branch for feature/FOO-456 has changes that are not pushed to the remote')
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-DependencyBranches @{
                'feature/FOO-456' = @("infra/add-services", "infra/refactor-api")
                'feature/FOO-123' = @("infra/add-services")
                'infra/add-services' = @("main")
                'infra/refactor-api' = @("main")
            }
        }

        Add-StandardTests
    }
}
