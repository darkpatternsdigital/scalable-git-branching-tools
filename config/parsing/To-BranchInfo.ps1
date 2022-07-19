. $PSScriptRoot/../Variables.ps1
. $PSScriptRoot/../branch-types.ps1

function To-BranchInfo($branchName) {
    return $branchTypes.Keys
        | Where-Object { $branchName -match $branchTypes[$_].regex }
        | ForEach-Object { & $branchTypes[$_].toInfo $branchName }
        | Where-Object { $_ -ne $nil }
        | Select-Object -First 1
}
