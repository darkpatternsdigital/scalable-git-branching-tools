#!/usr/bin/env pwsh

& $PSScriptRoot/_setup.ps1

Push-Location
try {
    cd origin

    /git-tools/init.ps1

    git add-deps main -target feature/add-item-1
    git add-deps main -target feature/add-item-2
    git add-deps main -target feature/change-existing-item-A
    git add-deps main -target feature/change-existing-item-B
    git add-deps feature/add-item-1 -target feature/subfeature

} finally {
    Pop-Location
}
