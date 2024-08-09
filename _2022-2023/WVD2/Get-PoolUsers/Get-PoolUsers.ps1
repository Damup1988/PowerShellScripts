$pools = Get-Content -Path "C:\_bufer\_scripts\WVD2\Get-PoolUsers\poolsV2.txt"

$data = @()
foreach ($pool in $pools) {
    Write-Host "doing $pool" -ForegroundColor Yellow
    $users = (Get-AzRoleAssignment `
        | Where-Object {$_.scope -like "*$pool*"} `
        | Select-Object SignInName).SignInName
    foreach ($user in $users) {
        $data += "$user;$pool"
    }
}

$data >> resultV2.txt