$allGPOs = Get-GPO -All

foreach ($gpo in $allGPOs) {
    [xml]$gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    $userEnabled = $gpoReport.GPO.User.Enabled
    $computerEnabled = $gpoReport.GPO.Computer.Enabled
    if ($gpoReport.GPO.Computer.ExtensionData.Extension.Policy.Name -contains "Configure user Group Policy loopback processing mode" `
        -and $userEnabled -eq "true" -and $computerEnabled -eq "true") {
        Write-Host "$($gpo.DisplayName)" -ForegroundColor Yellow
    }
}