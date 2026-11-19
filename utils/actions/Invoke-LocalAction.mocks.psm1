Import-Module -Scope Local "$PSScriptRoot/Invoke-LocalAction.internal.psm1"

function Initialize-FakeLocalAction(
    [Parameter(Mandatory)][string] $actionType,
    [Parameter()][scriptblock] $returns
) {
    # Pester 6 no longer falls through to the real command when no parameter
    # filter matches, so un-faked action types must use the real registry
    Mock -CommandName Get-LocalAction `
        -ModuleName "Invoke-LocalAction.internal" -MockWith {
            return (Get-LocalActionsRegistry)[$type]
        }
    Mock -CommandName Get-LocalAction `
        -ModuleName "Invoke-LocalAction.internal" `
        -ParameterFilter $([scriptblock]::Create("`$type -eq '$actionType'")) -MockWith {
            return $returns
        }.GetNewClosure()
}

Export-ModuleMember -Function Initialize-FakeLocalAction
