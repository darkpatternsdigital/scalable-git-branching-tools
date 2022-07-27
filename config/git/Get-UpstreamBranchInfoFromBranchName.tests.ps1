BeforeAll {
    . $PSScriptRoot/Get-UpstreamBranchInfoFromBranchName.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-UpstreamBranchInfoFromBranchName' {
    Context 'When Configured with an origin' {
        BeforeEach{
            Mock git {
                Write-Output "
                origin/feature/FOO-123
                origin/feature/FOO-124-comment
                origin/feature/FOO-124_FOO-125
                origin/feature/FOO-76
                origin/feature/XYZ-1-services
                origin/main
                origin/rc/2022-07-14
                origin/integrate/FOO-125_XYZ-1
                "
            } -ParameterFilter { ($args -join ' ') -eq 'branch -r' }
            
            Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream' } }
            
            Mock git {
                Write-Output "feature/FOO-124_FOO-125"
                Write-Output "feature/XYZ-1-services"
            } -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:integrate/FOO-125_XYZ-1'}
        }

        It 'reports main for no parents' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-123' | ForEach-Object { $_.branch } | Should -Be @('main')
        }
        It 'reports parent for single-depth entries' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-124_FOO-125' | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-124-comment')
        }
        It 'reports parent for multi-depth entries' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-124_FOO-125_FOO-126' | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-124_FOO-125')
        }
        It 'reports parents for integration branches' {
            Get-UpstreamBranchInfoFromBranchName 'integrate/FOO-125_XYZ-1' | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-124_FOO-125','feature/XYZ-1-services')
        }
        It 'reports integration parents for integration branches' {
            Get-UpstreamBranchInfoFromBranchName 'integrate/FOO-76_FOO-125_XYZ-1' | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-76','integrate/FOO-125_XYZ-1')
        }
        
        It 'reports origin/main for no parents when remote is requested' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-123' | ForEach-Object { ConvertTo-BranchName $_ -includeRemote } | Should -Be @('origin/main')
        }
        It 'reports parent for single-depth entries when remote is requested' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-124_FOO-125' | ForEach-Object { ConvertTo-BranchName $_ -includeRemote } | Should -Be @('origin/feature/FOO-124-comment')
        }
        It 'reports parent for multi-depth entries when remote is requested' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-124_FOO-125_FOO-126' | ForEach-Object { ConvertTo-BranchName $_ -includeRemote } | Should -Be @('origin/feature/FOO-124_FOO-125')
        }
        It 'reports parents for integration branches when remote is requested' {
            Get-UpstreamBranchInfoFromBranchName 'integrate/FOO-125_XYZ-1' | ForEach-Object { ConvertTo-BranchName $_ -includeRemote } | Should -Be @('origin/feature/FOO-124_FOO-125','origin/feature/XYZ-1-services')
        }
        It 'reports integration parents for integration branches when remote is requested' {
            Get-UpstreamBranchInfoFromBranchName 'integrate/FOO-76_FOO-125_XYZ-1' | ForEach-Object { ConvertTo-BranchName $_ -includeRemote } | Should -Be @('origin/feature/FOO-76','origin/integrate/FOO-125_XYZ-1')
        }
        
    }
    
    Context 'When Configured without a remote still finds the local main' {
        BeforeEach{
            Mock git {
                Write-Output "
                main
                "
            } -ParameterFilter { ($args -join ' ') -eq 'branch' }
            
            Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream' } }
        }

        It 'finds main' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-123' | ForEach-Object { $_.branch } | Should -Be @('main')
        }
        It 'finds main even with includeRemote' {
            Get-UpstreamBranchInfoFromBranchName 'feature/FOO-123' | ForEach-Object { ConvertTo-BranchName $_ -includeRemote } | Should -Be @('main')
        }
    }
}