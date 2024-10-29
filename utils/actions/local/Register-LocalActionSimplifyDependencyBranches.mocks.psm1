Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSimplifyDependencyBranches.psm1"

function Lock-LocalActionSimplifyDependencyBranches() {
    Mock -ModuleName 'Register-LocalActionSimplifyDependencyBranches' -CommandName Compress-DependencyBranches -MockWith {
        throw "Register-LocalActionSimplifyDependencyBranches was not set up for this test, $originalDependency"
    }
}

function Initialize-LocalActionSimplifyDependencyBranchesSuccess(
    [string[]] $from,
    [string[]] $to
) {
    Lock-LocalActionSimplifyDependencyBranches
    foreach ($branch in $from) {
        Initialize-AssertValidBranchName $branch
    }

    $contents = (@(
        "`$originalDependency.Count -eq $($from.Count)"
        $from | ForEach-Object { "`$originalDependency -contains '$_'" }
     ) | ForEach-Object { $_ } | Where-Object { $_ -ne $null }) -join ' -AND '

    $result = New-VerifiableMock `
        -CommandName Compress-DependencyBranches `
        -ModuleName 'Register-LocalActionSimplifyDependencyBranches' `
        -ParameterFilter $([scriptblock]::Create($contents))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            $to
        }.GetNewClosure()
    return $result
}

# Uses expected dependency branches to determine simplification
function Initialize-LocalActionSimplifyDependencyBranches(
    [string[]] $from
) {
    foreach ($branch in $from) {
        Initialize-AssertValidBranchName $branch
    }
}

Export-ModuleMember -Function Initialize-LocalActionSimplifyDependencyBranchesSuccess,Initialize-LocalActionSimplifyDependencyBranches
