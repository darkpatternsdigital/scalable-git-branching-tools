Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-DependencyBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-AllDependencyBranches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
	return Invoke-MockGitModule -ModuleName 'Select-AllDependencyBranches' @PSBoundParameters
}

function Initialize-AllDependencyBranches([PSObject] $dependencyConfiguration) {
	$dependency = Get-DependencyBranch
	$workDir = [System.IO.Path]::GetRandomFileName()
	Invoke-MockGit "rev-parse --show-toplevel" -MockWith $workDir

	$treeEntries = $dependencyConfiguration.Keys | ForEach-Object { "100644 blob $_-blob`t$_" } | Sort-Object
	Invoke-MockGit "ls-tree -r $dependency" -MockWith $treeEntries

	if ($dependencyConfiguration.Count -gt 0) {
		$result = ($dependencyConfiguration.Keys | ForEach-Object {
			"`t$_-blob`n$($dependencyConfiguration[$_] -join "`n")"
		}) -join "`n`n"
		Invoke-MockGit "cat-file --batch=`t%(objectname)" -MockWith $result
	}
}
Export-ModuleMember -Function Initialize-AllDependencyBranches
