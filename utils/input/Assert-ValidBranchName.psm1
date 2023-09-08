Import-Module -Scope Local "$PSScriptRoot/../framework/diagnostic-framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework/processlog-framework.psm1"

function Assert-ValidBranchName {
    [OutputType([string])]
    Param (
        [Parameter(Mandatory, ValueFromPipeline = $true)][string[]]$branchName,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

	
	BEGIN {}
	PROCESS
	{
        foreach ($branch in $branchName) {
            Invoke-ProcessLogs "git check-ref-format --branch $branch" {
                git check-ref-format --branch "$branch"
            } -quiet
            if ($global:LASTEXITCODE -ne 0) {
                Add-ErrorDiagnostic $diagnostics "Invalid branch name specified: '$branch'"
            }
        }
    }
    END {}
}

Export-ModuleMember -Function Assert-ValidBranchName