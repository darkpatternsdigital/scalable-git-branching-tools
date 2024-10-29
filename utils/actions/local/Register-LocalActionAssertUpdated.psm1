Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Invoke-AssertBranchUpToDateLocalAction {
    param(
        [Parameter()][string] $downstream,
        [Parameter()][string] $dependency,
        [hashtable] $commitMappingOverride = @{},

        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    # Verifies that everything in "dependency" is in "downstream". Asserts if not.
    $mergeResult = Invoke-MergeTogether `
        -source (Get-RemoteBranchRef $downstream) `
        -commitishes @(Get-RemoteBranchRef $dependency) `
        -messageTemplate 'Verification Only' `
        -commitMappingOverride $commitMappingOverride `
        -diagnostics $diagnostics `
        -noFailureMessages
    if ($mergeResult.failed) {
        Add-ErrorDiagnostic $diagnostics "The branch $dependency conflicts with $downstream"
    } elseif ($mergeResult.hasChanges) {
        Add-ErrorDiagnostic $diagnostics "The branch $dependency has changes that are not in $downstream"
    }

    return @{}
}

Export-ModuleMember -Function Invoke-AssertBranchUpToDateLocalAction
