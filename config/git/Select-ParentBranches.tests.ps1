BeforeAll {
    . $PSScriptRoot/Select-ParentBranches.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Select-ParentBranches' {
    BeforeEach{
        Mock git { # remote -r
            Write-Output "
            origin/feature/FOO-123
            origin/feature/FOO-124-comment
            origin/feature/FOO-124_FOO-125
            origin/feature/XYZ-1-services
            origin/main
            origin/rc/2022-07-14
            origin/integrate/FOO-125_XYZ-1
            "
        }
        
        $branches = Select-Branches
    }

    It 'reports main for no parents' {
        Select-ParentBranches 'feature/FOO-123' | Should -Be @('main')
    }
    It 'reports parent for single-depth entries' {
        Select-ParentBranches 'feature/FOO-124_FOO-125' | Should -Be @('feature/FOO-124-comment')
    }
    It 'reports parent for multi-depth entries' {
        Select-ParentBranches 'feature/FOO-124_FOO-125_FOO-126' | Should -Be @('feature/FOO-124_FOO-125')
    }
    It 'reports parents for integration branches' {
        Select-ParentBranches 'integrate/FOO-125_XYZ-1' | Should -Be @('feature/FOO-124_FOO-125','feature/XYZ-1-services')
    }
}