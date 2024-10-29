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
    [Parameter()][string] $dependants,
    [Parameter()][string] $dependency,
    [Parameter()][Hashtable] $initialCommits = @{},
    [switch] $withChanges,
    [switch] $withConflict
) {
    $resultCommit = $initialCommits[$dependants] ?? 'result-commitish'
    $dependants = Get-RemoteBranchRef $dependants
    $dependency = Get-RemoteBranchRef $dependency

    $base = @{
        allBranches = @($dependency)
        initialCommits = (Get-CommitsWithRemote $initialCommits)
        source = $dependants
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
