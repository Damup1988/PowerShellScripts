function Transform-OU ($OU) {
    $m = $OU.Split('/')
    $c = $m.Count
    $newArray = @()
    foreach ($x in $m) {
     $newArray += "OU=$($m[$c-1])"
     $c = $c - 1
    }
    $k = $($newArray -join ',').Replace(",OU=EMEA.IPG.CORP", "")
    $result = "$k,$domain"
    return $result
}
 
$gpoName = "IPG_EMEA_LogonInfo_ComputerDescription_and_Attribute"
$domain = "DC=EMEA,DC=IPG,DC=CORP"

$gpo = Get-GPO $gpoName
[xml]$gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
$OUs = $gpoReport.GPO.LinksTo.SOMPath | ForEach-Object {Transform-OU -OU $_}

foreach ($OU in $OUs) {
    $GPOsNames = (Get-GPInheritance -Target $OU).InheritedGpoLinks.displayname
    foreach ($GPO in $GPOsNames) {
        [xml]$gpoReport = Get-GPOReport -Guid $(Get-GPO $GPO).Id -ReportType Xml
        if ($gpoReport.GPO.Computer.ExtensionData.Extension.Policy.Name -contains "Configure user Group Policy loopback processing mode" `
            -and $null -ne $gpoReport.gpo.User.ExtensionData) {
            Write-Host "$GPO has loopback enabled and has user settings" -ForegroundColor Yellow
        }
        elseif ($gpoReport.GPO.Computer.ExtensionData.Extension.Policy.Name -contains "Configure user Group Policy loopback processing mode") {
            Write-Host "$GPO has loopback enabled" -ForegroundColor Yellow
        }
        elseif ($null -ne $gpoReport.gpo.User.ExtensionData) {
            Write-Host "$GPO has user settings" -ForegroundColor Yellow
        }
    }
}