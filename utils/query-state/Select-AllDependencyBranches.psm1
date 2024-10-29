Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-DependencyBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

# allDependencies is a hashmap where the key is the git working directory and
$allDependencies = @{}

function Select-Override(
	[Parameter(Mandatory)][System.Collections.Hashtable] $first,
	[Parameter(Mandatory)][System.Collections.Hashtable] $second) {

	$result = $first + @{}
	foreach ($key in $second.Keys) {
		$result[$key] = $second[$key]
	}
	return $result
}

function Select-AllDependencyBranches([switch]$refresh, [Parameter()][AllowNull()] $overrideDependencies) {
	$workDir = Invoke-ProcessLogs "git rev-parse --show-toplevel" {
		git rev-parse --show-toplevel
	} -allowSuccessOutput
	if ($allDependencies[$workDir] -AND -not $refresh) {
		return $overrideDependencies ? (Select-Override -first $allDependencies[$workDir] -second (ConvertTo-Hashtable $overrideDependencies)) : $allDependencies[$workDir]
	}

	$nodes = $allDependencies[$workDir] = @{}

	$dependencyBranch = Get-DependencyBranch

	# --format would be nice to use, but it was introduced in git version 2.36, which isn't the default installed yet.
	# Rather than adding a version check, I figured parsing it would be fine.
	# The default format is: permission ' blob ' hash '`t' branchName
	$treeEntries = (Invoke-ProcessLogs "git ls-tree -r $dependencyBranch" {
		git ls-tree -r $dependencyBranch
	} -allowSuccessOutput) | ForEach-Object {
		$record, $name = $_.Split("`t")
		$permission, $type, $hash = $record.Split(' ')
		@{ hash = $hash; name = $name }
	}

	# build "$blobs", a Dictionary<hash, contents-split-by-line>
	# TODO: there may be a way to make this more efficient yet.
	$hashes = $treeEntries | ForEach-Object { $_.hash }
	if ($hashes) {
		$hashEntries = (Invoke-ProcessLogs "git cat-file '--batch=`t%(objectname)'" {
			# --batch gives a header, in this case:"`t<blobhash>", followed by a new line,
			# followed by the contents of the file, followed by two line breaks.
			# Empty files, therefore, would have three subsequent line breaks and make the whole result messy
			# I hope that no one adds files with "`t" in them.
			$hashes | git cat-file "--batch=`t%(objectname)"
		} -allowSuccessOutput) -join "`n" -split "`t" | Where-Object { $_ } | ForEach-Object { $_.Trim() }
		$blobs = @{}
		foreach ($entry in $hashEntries) {
			$lines = $entry.Split("`n")
			$blobs[$lines[0]] = $lines | Select-Object -Skip 1
		}

		foreach ($entry in $treeEntries) {
			[string[]]$nodes[$entry.name] = $blobs[$entry.hash]
		}
	}

	return $overrideDependencies ? (Select-Override -first $nodes -second (ConvertTo-Hashtable $overrideDependencies)) : $nodes
}

function Clear-AllDependencyBranchCache([string] $workDir) {
	if ($workDir) {
		$allDependencies[$workDir] = $null
	} else {
		$allDependencies = @{}
	}
}

# This module is intentionally kept internal to the query-state folder in case of breaking changes.
# Use `Select-DependencyBranches` or other query-state utility instead.
Export-ModuleMember -Function Select-AllDependencyBranches, Clear-AllDependencyBranchCache
