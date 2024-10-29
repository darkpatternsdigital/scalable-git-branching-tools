Import-Module -Scope Local "$PSScriptRoot/query-state/Assert-CleanWorkingDirectory.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Configuration.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-DependencyBranch.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Select-DependencyBranches.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Update-GitRemote.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-CurrentBranch.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-GitFile.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-MergeTree.mocks.psm1"

Export-ModuleMember -Function `
    Initialize-CleanWorkingDirectory, Initialize-DirtyWorkingDirectory, Initialize-UntrackedFiles `
    , Initialize-ToolConfiguration `
    , Initialize-FetchDependencyBranch `
    , Initialize-DependencyBranches `
    , Initialize-UpdateGitRemote `
    , Initialize-CurrentBranch, Initialize-NoCurrentBranch `
    , Initialize-OtherGitFilesAsBlank, Initialize-GitFile `
    , Initialize-MergeTree `

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-BranchCommit.mocks.psm1"
Export-ModuleMember -Function Initialize-GetBranchCommit

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-BranchSyncState.mocks.psm1"
Export-ModuleMember -Function Initialize-RemoteBranchBehind, Initialize-RemoteBranchAhead, Initialize-RemoteBranchNotTracked, Initialize-RemoteBranchInSync, Initialize-RemoteBranchAheadAndBehind

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-LocalBranchForRemote.mocks.psm1"
Export-ModuleMember -Function Initialize-GetLocalBranchForRemote

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-AllDependencyBranches.mocks.psm1"
Export-ModuleMember -Function Initialize-AllDependencyBranches

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-Branches.mocks.psm1"
Export-ModuleMember -Function Initialize-SelectBranches
