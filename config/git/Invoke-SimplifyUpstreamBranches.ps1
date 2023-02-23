Import-Module -Scope Local "$PSScriptRoot/Select-Branches.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-UpstreamBranches.psm1"

function Invoke-SimplifyUpstreamBranches([PSObject[]] $originalUpstream, [PSObject[]] $allBranchInfo, [Parameter(Mandatory)][PSObject] $config) {
    if ($allBranchInfo -eq $nil) {
        $allBranchInfo = Select-Branches
    }

    $upstreamNames = $originalUpstream | ForEach-Object { $_.branch }
    $possibleResult = $allBranchInfo | Where-Object { $upstreamNames -contains $_.branch }
    do {
        $len = $possibleResult.Length
        $parents = $possibleResult | ForEach-Object { return Select-UpstreamBranches $_.branch -config $config } | ForEach-Object {$_} | select -uniq
        $possibleResult = $possibleResult | Where-Object { $parents -notcontains $_.branch }
    } until ($len -eq $possibleResult.Length)

    return $possibleResult
}
