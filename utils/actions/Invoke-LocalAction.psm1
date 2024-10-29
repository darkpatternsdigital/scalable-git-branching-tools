Import-Module -Scope Local "$PSScriptRoot/Invoke-LocalAction.internal.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAddDiagnostic.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertPushed.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertUpdated.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionEvaluate.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetAllDependencies.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetDependency.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetDownstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionFilterBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionMergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionRecurse.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSetDependency.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSimplifyDependencyBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionDependenciesUpdated.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionValidateBranchNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertExistence.psm1"

$localActions = Get-LocalActionsRegistry
$localActions['add-diagnostic'] = ${function:Invoke-AddDiagnosticLocalAction}
$localActions['assert-existence'] = ${function:Invoke-AssertBranchExistenceLocalAction}
$localActions['assert-pushed'] = ${function:Invoke-AssertBranchPushedLocalAction}
$localActions['assert-updated'] = ${function:Invoke-AssertBranchUpToDateLocalAction}
$localActions['evaluate'] = ${function:Invoke-EvaluateLocalAction}
$localActions['filter-branches'] = ${function:Invoke-FilterBranchesLocalAction}
$localActions['get-all-dependencies'] = ${function:Invoke-GetAllDependenciesLocalAction}
$localActions['get-downstream'] = ${function:Invoke-GetDownstreamLocalAction}
$localActions['get-dependency'] = ${function:Invoke-GetDependencyLocalAction}
$localActions['merge-branches'] = ${function:Invoke-MergeBranchesLocalAction}
$localActions['recurse'] = ${function:Invoke-RecursiveScriptLocalAction}
$localActions['set-dependency'] = ${function:Invoke-SetDependencyLocalAction}
$localActions['simplify-dependency'] = ${function:Invoke-SimplifyDependencyLocalAction}
$localActions['dependencies-updated'] = ${function:Invoke-DependenciesUpdatedLocalAction}
$localActions['validate-branch-names'] = ${function:Invoke-AssertBranchNamesLocalAction}

Export-ModuleMember -Function Invoke-LocalAction
