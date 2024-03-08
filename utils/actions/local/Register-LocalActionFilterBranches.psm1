Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionFilterBranches([PSObject] $localActions) {
    $localActions['filter-branches'] = {
        param(
            [Parameter()][AllowEmptyCollection()][string[]] $include,
            [Parameter()][AllowEmptyCollection()][string[]] $exclude,
            
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        
        [string[]]$result = $include | Where-Object { $_ -notin $exclude } | Get-Unique
        
        return $result
    }
}

Export-ModuleMember -Function Register-LocalActionFilterBranches
