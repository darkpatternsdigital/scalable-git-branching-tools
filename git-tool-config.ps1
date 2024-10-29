#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $remote,
    [Parameter()][String] $dependencyBranch,
    [Parameter()][String] $defaultServiceLine,
	[Switch] $enableAtomicPush,
	[Switch] $disableAtomicPush
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"

$oldConfig = Get-Configuration

if ($remote -ne '') {
    if ((git remote) -notcontains $remote) {
        throw "$remote not a valid remote for the repo."
    } else {
        git config scaled-git.remote $remote
    }
    Write-Host "Set remote: $remote"
} else {
    $remote = $oldConfig.remote
    Write-Host "Using previous remote: $remote"
}

if ($dependencyBranch -ne '') {
    git config scaled-git.dependencyBranch $dependencyBranch
    Write-Host "Set dependency tracking branch: $dependencyBranch"
} else {
    Write-Host "Using previous dependency tracking branch: $($oldConfig.dependencyBranch)"
}

if ($defaultServiceLine -ne '') {
    $expected = $remote -eq $nil ? $defaultServiceLine : "$remote/$defaultServiceLine"
    $branches = $remote -eq $nil ? (git branch --format '%(refname:short)') : (git branch -r --format '%(refname:short)')
    if ($branches -notcontains $expected) {
        throw "$expected is not found"
    }
    git config scaled-git.defaultServiceLine $defaultServiceLine
    Write-Host "Set default service line: $defaultServiceLine"
} else {
    Write-Host "Using previous default service line: $($oldConfig.defaultServiceLine)"
}

if ($enableAtomicPush) {
	git config scaled-git.atomicPushEnabled true
	Write-Host "Enabling atomic push"
}

if ($disableAtomicPush) {
	git config scaled-git.atomicPushEnabled false
	Write-Host "Disabling atomic push"
}
