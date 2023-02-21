. $PSScriptRoot/Get-UpstreamBranch.ps1
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"

function Select-UpstreamBranches([String]$branchName, [switch] $includeRemote, [switch] $recurse, [string[]] $exclude, [Parameter(Mandatory)][PSObject] $config) {
    $upstreamBranch = Get-UpstreamBranch $config
    $parentBranches = [string[]](Get-GitFile $branchName $upstreamBranch)

    $parentBranches = $parentBranches | Where-Object { $exclude -notcontains $_ }

    if ($parentBranches -eq $nil -OR $parentBranches.length -eq 0) {
        return [string[]](@())
    }

    if ($recurse) {
        $currentExclude = [string[]]( @($branchName, $exclude) | ForEach-Object { $_ } )
        $finalParents = [string[]]( $parentBranches | ForEach-Object {
            $newParents = [string[]](Select-UpstreamBranches $_ -recurse -exclude $currentExclude -config $config)
            if ($newParents -eq $nil) {
                return @()
            }
            $currentExclude = [string[]]( @($currentExclude, $newParents) | ForEach-Object { $_ } )
            return $newParents
        } | ForEach-Object { $_ } )
        $parentBranches = [string[]]( @( $parentBranches, $finalParents ) | ForEach-Object { $_ } | Where-Object { $_ -ne $nil} )
    }

    if ($includeRemote) {
        return $parentBranches | ForEach-Object { $config.remote -eq $nil ? $_ : "$($config.remote)/$_" }
    } else {
        return $parentBranches
    }
}
