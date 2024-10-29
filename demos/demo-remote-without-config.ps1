#!/usr/bin/env pwsh

function ThrowOnNativeFalure {
    if ($LASTEXITCODE -ne 0) {
        throw "Native Falure - exit code $LASTEXITCODE"
    }
}

& $PSScriptRoot/_setup.ps1

git clone ./origin local

cd local
/git-tools/init.ps1

git new feature/PS-1
ThrowOnNativeFalure

if ((git rev-parse origin/main) -ne (git rev-parse HEAD)) {
    throw 'HEAD does not point to the same commit as main';
}

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name did not match expected';
}

$dependencyOfNewFeature = [string[]](git show-deps)
if ($dependencyOfNewFeature -notcontains 'main') {
    throw "Expected main to be dependency of the current branch; found: $(ConvertTo-Json $dependencyOfNewFeature)"
}

git rc rc/test -d feature/add-item-1,feature/add-item-2
ThrowOnNativeFalure

if ((git branch --show-current) -ne 'feature/PS-1') {
    throw 'Branch name should not have changed';
}

git verify-updated rc/test
ThrowOnNativeFalure

$branches = (git branch -a) | ForEach-Object { $_.Trim() }
if ($branches -notcontains 'remotes/origin/rc/test') {
    throw "Expected that rc/test was on origin; found $(ConvertTo-Json $branches)"
}
if ($branches -notcontains 'remotes/origin/feature/PS-1') {
    throw 'Expected that feature/PS-1 was on origin'
}

git branch -a > ../report.txt
