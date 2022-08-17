BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
    Mock -CommandName Set-UpstreamBranches { throw "Unexpected parameters for Set-UpstreamBranches: $branchName $upstreamBranches $commitMessage" }

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Invoke-WriteTree.ps1
    Mock -CommandName Invoke-WriteTree { throw "Unexpected parameters for Invoke-WriteTree: $treeEntries" }
}

Describe 'git-new' {
    It 'handles standard functionality' {
        . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        # Mock git -ParameterFilter { ($args -join ' ') -eq 'config scaled-git.remote' } {}
        # Mock git -ParameterFilter { ($args -join ' ') -eq 'remote' } {}
        # Mock git -ParameterFilter { ($args -join ' ') -eq 'config scaled-git.upstreamBranch' } {}
        # Mock git -ParameterFilter { ($args -join ' ') -eq 'config scaled-git.defaultServiceLine' } { 'main' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch' } {
            Write-Output 'main'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' } {
            $Global:LASTEXITCODE = 0
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'clean -n' } {}
        Mock -CommandName Set-UpstreamBranches -ParameterFilter { 
            $branchName -eq 'feature/PS-100-some-work' `
                -AND ($upstreamBranches -join ' ') -eq 'main'
        } {}
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch feature/PS-100-some-work main --quiet' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout feature/PS-100-some-work --quiet' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
    }

    It 'creates a local branch when no remotes are configured' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        . $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
        . $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1

        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }
        Mock -CommandName Set-UpstreamBranches -ParameterFilter { 
            $branchName -eq 'feature/PS-100-some-work' `
                -AND ($upstreamBranches -join ' ') -eq 'main'
        } {}
        Mock -CommandName Assert-CleanWorkingDirectory {}
        Mock -CommandName Invoke-CreateBranch -ParameterFilter {
            $branchName -eq 'feature/PS-100-some-work' `
                -AND $source -eq 'main'
        } {}
        Mock -CommandName Invoke-CheckoutBranch -ParameterFilter {
            $branchName -eq 'feature/PS-100-some-work'
        } {}

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
    }

    It 'creates a local branch from the specified branch when no remotes are configured' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        . $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
        . $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1

        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream' } }
        Mock -CommandName Set-UpstreamBranches -ParameterFilter { 
            $branchName -eq 'feature/PS-600-some-work' `
                -AND ($upstreamBranches -join ' ') -eq 'infra/foo'
        } {}
        Mock -CommandName Assert-CleanWorkingDirectory {}
        Mock -CommandName Invoke-CreateBranch -ParameterFilter {
            $branchName -eq 'feature/PS-600-some-work' `
                -AND $source -eq 'infra/foo'
        } {}
        Mock -CommandName Invoke-CheckoutBranch -ParameterFilter {
            $branchName -eq 'feature/PS-600-some-work'
        } {}

        & $PSScriptRoot/git-new.ps1 feature/PS-600-some-work -from 'infra/foo' -m 'some work'
    }
    
    It 'creates a remote branch when a remote is configured' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        . $PSScriptRoot/config/git/Update-Git.ps1
        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        . $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
        . $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1

        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }
        Mock -CommandName Update-Git { }
        Mock -CommandName Set-UpstreamBranches -ParameterFilter { 
            $branchName -eq 'feature/PS-100-some-work' `
                -AND ($upstreamBranches -join ' ') -eq 'main'
        } {}
        Mock -CommandName Assert-CleanWorkingDirectory {}
        Mock -CommandName Invoke-CreateBranch -ParameterFilter {
            $branchName -eq 'feature/PS-100-some-work' `
                -AND $source -eq 'origin/main'
        } {}
        Mock -CommandName Invoke-CheckoutBranch -ParameterFilter {
            $branchName -eq 'feature/PS-100-some-work'
        } {}

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
    }
    
    It 'creates a remote branch when a remote is configured' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        . $PSScriptRoot/config/git/Update-Git.ps1
        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        . $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
        . $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1

        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream' } }
        Mock -CommandName Update-Git { }
        Mock -CommandName Set-UpstreamBranches -ParameterFilter { 
            $branchName -eq 'feature/PS-100-some-work' `
                -AND ($upstreamBranches -join ' ') -eq 'infra/foo'
        } {}
        Mock -CommandName Assert-CleanWorkingDirectory {}
        Mock -CommandName Invoke-CreateBranch -ParameterFilter {
            $branchName -eq 'feature/PS-100-some-work' `
                -AND $source -eq 'origin/infra/foo'
        } {}
        Mock -CommandName Invoke-CheckoutBranch -ParameterFilter {
            $branchName -eq 'feature/PS-100-some-work'
        } {}

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -from 'infra/foo' -m 'some work'
    }
    
}
