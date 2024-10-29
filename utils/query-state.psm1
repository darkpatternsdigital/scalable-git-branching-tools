Import-Module -Scope Local "$PSScriptRoot/query-state/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Update-GitRemote.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Compress-DependencyBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Select-DependencyBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-DependencyBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-MergeTree.psm1"

Export-ModuleMember -Function Get-Configuration `
    , Update-GitRemote `
    , Assert-CleanWorkingDirectory `
    , Compress-DependencyBranches `
    , Select-DependencyBranches `
    , Get-DependencyBranch `
    , Get-CurrentBranch `
    , Get-GitFile `
    , Get-MergeTree `

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-BranchSyncState.psm1"
Export-ModuleMember -Function Get-BranchSyncState

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-BranchCommit.psm1"
Export-ModuleMember -Function Get-BranchCommit

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-LocalBranchForRemote.psm1"
Export-ModuleMember -Function Get-LocalBranchForRemote

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-RemoteBranchRef.psm1"
Export-ModuleMember -Function Get-RemoteBranchRef

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-Branches.psm1"
Export-ModuleMember -Function Select-Branches

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-AllDependencyBranches.psm1"
Export-ModuleMember -Function Select-AllDependencyBranches

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-DependantBranches.psm1"
Export-ModuleMember -Function Select-DependantBranches
