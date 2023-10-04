Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

# TODO: remove quiet
function Invoke-CheckoutBranch(
    [String]$branchName,
    [switch]$quiet,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    Invoke-ProcessLogs "git checkout $branchName" {
        git checkout $branchName
    } -quiet
    if ($LASTEXITCODE -ne 0) {
        Add-ErrorDiagnostic $diagnostics "Could not checkout newly created branch '$branchName'"
    }

    if (-not $quiet -AND $null -eq $diagnostics) {
        Write-Host "Checked out new branch '$branchName'."
    }
}
Export-ModuleMember -Function Invoke-CheckoutBranch
