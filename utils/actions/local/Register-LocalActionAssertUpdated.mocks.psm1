Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionAssertUpdated.psm1"

function Get-CommitsWithRemote(
    [Parameter()][Hashtable] $initialCommits
) {
    return $initialCommits.Keys | ConvertTo-HashMap -getKey { Get-RemoteBranchRef $_ } -getValue { $initialCommits[$_] }
}

function Initialize-LocalActionAssertUpdated(
    [Parameter()][string] $downstream,
    [Parameter()][string] $dependency,
    [Parameter()][Hashtable] $initialCommits = @{},
    [switch] $withChanges,
    [switch] $withConflict
) {
    $resultCommit = $initialCommits[$downstream] ?? 'result-commitish'
    $downstream = Get-RemoteBranchRef $downstream
    $dependency = Get-RemoteBranchRef $dependency

    $base = @{
        allBranches = @($dependency)
        initialCommits = (Get-CommitsWithRemote $initialCommits)
        source = $downstream
        messageTemplate = 'Verification Only'
        resultCommitish = $resultCommit
    }

    if ($withConflict) {
        Initialize-MergeTogether @base `
            -successfulBranches @() `
            -noChangeBranches @()
    } elseif ($withChanges) {
        Initialize-MergeTogether @base `
            -successfulBranches @($dependency) `
            -noChangeBranches @()
    } else {
        Initialize-MergeTogether @base `
            -successfulBranches @() `
            -noChangeBranches @($dependency)
    }
}

Export-ModuleMember -Function Initialize-LocalActionAssertUpdated
