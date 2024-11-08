Describe 'ConvertFrom-ParameterizedString' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
    }

    BeforeEach {
        $fw = Register-Framework
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
    }

    It 'can evaluate from params' {
        $params = @{ foo = 'bar' }
        $result = ConvertFrom-ParameterizedString -script '$($params.foo)' -variables @{ config=@{}; params=$params; actions=@{} }
        $result.result | Should -Be 'bar'
        $result.fail | Should -Be $false
    }

    It 'can evaluate from actions including quotes' {
        $actions = @{
            'create-branch' = @{
                outputs = @{
                    commit = 'baadf00d'
                }
            }
        }
        $result = ConvertFrom-ParameterizedString -script '$($actions["create-branch"].outputs["commit"])' -variables @{ config=@{}; params=@{}; actions=$actions }
        $result.result | Should -Be 'baadf00d'
        $result.fail | Should -Be $false
    }

    It 'returns null if accessing an action that does not exist' {
        $result = ConvertFrom-ParameterizedString -script '$($actions["create-branch"].outputs["commit"])' -variables @{ config=@{}; params=@{}; actions=@{} }
        $result.result | Should -Be $null
        $result.fail | Should -Be $true
    }

    It 'returns null if an error occurs' {
        $result = ConvertFrom-ParameterizedString -script '$($config.dependencyBranch)' -variables @{ config=@{}; params=@{}; actions=@{} }
        $result.result | Should -Be $null
        $result.fail | Should -Be $true
    }

    It 'reports warnings if diagnostics are provided' {
        $result = ConvertFrom-ParameterizedString -script '$($config.dependencyBranch)' -variables @{ config=@{}; params=@{}; actions=@{} } -diagnostics $diag
        $result.result | Should -Be $null
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output | Should -Be @('WARN: Unable to evaluate script: ''$($config.dependencyBranch)''')
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $result = ConvertFrom-ParameterizedString -script '$($config.dependencyBranch)' -variables @{ config=@{}; params=@{}; actions=@{} } -diagnostics $diag -failOnError
        $result.result | Should -Be $null
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output | Should -Be @('ERR:  Unable to evaluate script: ''$($config.dependencyBranch)''')
    }

}
