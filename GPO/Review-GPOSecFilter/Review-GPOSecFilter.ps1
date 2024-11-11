$allGPOs = Get-GPO -All

foreach ($gpo in $allGPOs) {
    $GpoPermissions = (Get-GPPermission -Name $gpo.DisplayName -All | Where-Object {$_.Permission -eq "GpoApply"}).trustee.name
    if ($GpoPermissions.Count -gt 1 -and $GpoPermissions -contains "Authenticated Users") {
        Write-Host "$($gpo.DisplayName)" -ForegroundColor Yellow
    }
}