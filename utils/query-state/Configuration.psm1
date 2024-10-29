
function Get-Configuration() {
    $remote = Get-ConfiguredRemote
    return @{
        remote = $remote
        dependencyBranch = Get-ConfiguredDependencyBranch
        defaultServiceLine = Get-ConfiguredDefaultServiceLine -remote $remote
        atomicPushEnabled = Get-ConfiguredAtomicPushEnabled
    }
}

function Get-ConfiguredRemote() {
    $result = git config scaled-git.remote
    if ($null -ne $result) { return $result }
    return git remote | Select-Object -First 1
}

function Get-ConfiguredDependencyBranch() {
    $result = git config scaled-git.dependencyBranch
    if ($null -ne $result) {
        return $result;
    }
    return '$dependencies'
}

function Get-ConfiguredDefaultServiceLine([string]$remote) {
    $result = git config scaled-git.defaultServiceLine
    if ($null -ne $result) { return $result }

    git rev-parse --verify ($null -eq $remote -OR $remote -eq '' ? 'main' : "$($remote)/main") -q > $null 2> $null
    if ($LASTEXITCODE -eq 0) {
        return "main"
    }
    return $null
}

function Get-ConfiguredAtomicPushEnabled() {
	$result = git config scaled-git.atomicPushEnabled
	if ($null -ne $result) { return [bool]::Parse($result) }
	return $true
}

Export-ModuleMember -Function Get-Configuration
