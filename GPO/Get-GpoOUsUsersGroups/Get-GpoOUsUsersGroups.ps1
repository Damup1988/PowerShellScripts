$policyName = "Block-Windows-Update-Notifications"
$domain = "DC=ipgphotonics,DC=com"

$gpoId = (Get-GPO $policyName).Id
[xml]$gpoReport = Get-GPOReport -Guid $gpoId -ReportType Xml
$OUs = $gpoReport.gpo.LinksTo.SOMPath

$allOUs = @()
foreach ($OU in $OUs) {
   $m = $OU.Split('/')
   $c = $m.Count
   $newArray = @()
   foreach ($x in $m) {
    $newArray += "OU=$($m[$c-1])"
    $c = $c - 1
   }
   $k = $($newArray -join ',').Replace(",OU=ipgphotonics.com", "")
   $result = "$k,$domain"
   $allOUs += $result
}
$allOUs

Write-Host "USERS" -ForegroundColor Yellow
$users = @()
foreach ($OU in $allOUs) {
    $users += Get-ADUser -SearchBase $OU -Filter * -Properties description | Where-Object {$_.enabled -eq $true} | Select-Object name,enabled,description,DistinguishedName
}
if ($users.Count -ne 0) {
    $users | Sort-Object -Unique | Export-Csv -Path "usersFor$policyName.csv" -Delimiter ';' -NoTypeInformation
}
else {
    Write-Host "NO ACTIVE USERS" -ForegroundColor Red
}

Write-Host "COMPUTERS" -ForegroundColor Yellow
$computers = @()
foreach ($OU in $allOUs) {
    $computers += Get-ADComputer -SearchBase $OU -Filter * -Properties description | Where-Object {$_.enabled -eq $true} | Select-Object name,enabled,description,DistinguishedName
}
if ($computers.Count -ne 0) {
    $computers | Sort-Object -Unique | Export-Csv -Path "computersFor$policyName.csv" -Delimiter ';' -NoTypeInformation
}
else {
    Write-Host "NO ACTIVE COMPUTERS" -ForegroundColor Red
}