. $PSScriptRoot/../core/Coalesce.ps1
. $PSScriptRoot/../branch-utils/ConvertTo-BranchInfo.ps1
. $PSScriptRoot/../branch-utils/Get-Tickets.ps1
. $PSScriptRoot/Select-Branches.ps1

function Select-ParentBranches([String]$branchName, [switch] $includeRemote) {
    function ConvertTo-BranchName($branchInfo) {
        return $includeRemote ? "$($branchInfo.remote)/$($branchInfo.branch)" : $branchInfo.branch
    }

    # TODO: check "config branch" for things like RC branches
    $branches = Select-Branches

    $info = ConvertTo-BranchInfo $branchName

    $parentTickets = $info.tickets
    if ($parentTickets -eq $nil -AND $info.parents -ne $nil) {
        $parentTickets = $info.parents[-1]
    }
    if ($parentTickets -eq $nil) {
        $parentTickets = @()
    }
    $parentTickets = $parentTickets | ForEach-Object {$_} # flatten the array
    if ($parentTickets.Length -eq 0) {
        $serviceLines = @($branches | Where-Object { $_.type -eq 'service-line' } | ForEach-Object { ConvertTo-BranchName $_ })
        if ($serviceLines.Length -gt 1) {
            $allLines = $serviceLines -join ' '
            throw "Found more than one service line ($serviceLines) - please specify the base."
        }
        return $serviceLines
    } else {
        $possibleResult = $branches | Where-Object {
            $tickets = (Get-Tickets $_)
            if ($tickets.Length -eq 0) { return $false }
            $intersection = $tickets | Where-Object { $parentTickets -contains $_ }
            return $intersection.Length -eq $tickets.Length -AND $_.branch -ne $branchName
        }

        do {
            $len = $possibleResult.Length
            $parents = $possibleResult | ForEach-Object { return Select-ParentBranches $_.branch -includeRemote:$includeRemote } | ForEach-Object {$_} | select -uniq
            $possibleResult = $possibleResult | Where-Object { $parents -notcontains (ConvertTo-BranchName $_) }
        } until ($len -eq $possibleResult.Length)

        return $possibleResult | ForEach-Object { ConvertTo-BranchName $_ }
    }
}
