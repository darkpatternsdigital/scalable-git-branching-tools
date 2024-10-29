Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Invoke-AssertBranchUpToDateLocalAction {
    param(
        [Parameter()][string] $dependants,
        [Parameter()][string] $dependency,
        [hashtable] $commitMappingOverride = @{},

        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    # Verifies that everything in "dependency" is in "dependants". Asserts if not.
    $mergeResult = Invoke-MergeTogether `
        -source (Get-RemoteBranchRef $dependants) `
        -commitishes @(Get-RemoteBranchRef $dependency) `
        -messageTemplate 'Verification Only' `
        -commitMappingOverride $commitMappingOverride `
        -diagnostics $diagnostics `
        -noFailureMessages
    if ($mergeResult.failed) {
        Add-ErrorDiagnostic $diagnostics "The branch $dependency conflicts with $dependants"
    } elseif ($mergeResult.hasChanges) {
        Add-ErrorDiagnostic $diagnostics "The branch $dependency has changes that are not in $dependants"
    }

    return @{}
}

Export-ModuleMember -Function Invoke-AssertBranchUpToDateLocalAction
