Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSetDependency.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"

function Lock-LocalActionSetDependency() {
    Mock -ModuleName 'Register-LocalActionSetDependency' -CommandName Set-GitFiles -MockWith {
        throw "Register-LocalActionSetDependency was not set up for this test, $commitMessage, $($files | ConvertTo-Json)"
    }
}

function Initialize-LocalActionSetDependency([PSObject] $dependencyBranches, [string] $message, [string] $commitish) {
    Lock-LocalActionSetDependency
    $contents = (@(
        '' -ne $message ? "`$message -eq '$($message.Replace("'", "''"))'" : $null
        $null -ne $dependencyBranches ? @(
            "`$files.Keys.Count -eq $($dependencyBranches.Keys.Count)"
            ($dependencyBranches.Keys | ForEach-Object {
                if ($null -eq $dependencyBranches[$_] -OR $dependencyBranches[$_].length -eq 0) {
                    "`$files['$_'] -eq `$null"
                } else {
                    "`$files['$_'].split(`"``n`").Count -eq $($dependencyBranches[$_].Count + 1)"
                    foreach ($branch in $dependencyBranches[$_]) {
                        "`$files['$_'].split(`"``n`") -contains '$branch'"
                    }
                }
            })
        ) : $null
     ) | ForEach-Object { $_ } | Where-Object { $_ -ne $null }) -join ' -AND '

    $result = New-VerifiableMock `
        -CommandName Set-GitFiles `
        -ModuleName 'Register-LocalActionSetDependency' `
        -ParameterFilter $([scriptblock]::Create($contents))
    Invoke-WrapMock $result -MockWith {
            $global:LASTEXITCODE = 0
            $commitish
        }.GetNewClosure()
    return $result
}
Export-ModuleMember -Function Lock-LocalActionSetDependency, Initialize-LocalActionSetDependency
