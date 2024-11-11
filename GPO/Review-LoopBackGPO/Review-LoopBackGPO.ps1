function Transform-OU ($OU) {
    $m = $OU.Split('/')
    $c = $m.Count
    $newArray = @()
    foreach ($x in $m) {
     $newArray += "OU=$($m[$c-1])"
     $c = $c - 1
    }
    $k = $($newArray -join ',').Replace(",OU=ipgphotonics.com", "")
    $result = "$k,$domain"
    return $result
 }
 
 $loopBackPolicyName = "IPGL_RDP_LimitAccessConfigure"
 $gpo = Get-GPO $loopBackPolicyName
 [xml]$gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
 $OUs = $gpoReport.GPO.LinksTo.SOMPath
 
 <#$data = @()
 $allGPOs = Get-GPO -All
 foreach ($gpo in $allGPOs) {
     [xml]$gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
     $OUs = $gpoReport.GPO.LinksTo.SOMPath
     foreach ($OU in $OUs) {
         $MyPSCustomObj = New-Object -TypeName PSObject
 
         $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GPOName" -Value $gpo.DisplayName
         $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OU" -Value $OU
         $data += $MyPSCustomObj
     }
 }#>
 #$data = Import-Csv -Path "C:\Users\dsafarov-fa\Documents\_allGPOsAndOUs.csv" -Delimiter ';'
 
 foreach ($OU in $OUs) {
     $DisOU = Transform-OU -OU $OU
     Write-Host "Checking $DisOU" -ForegroundColor DarkYellow
     $amountOfEnabledComputers = (Get-ADComputer -SearchBase $DisOU -Filter * | Where-Object {$_.enabled -eq $true}).count
     if ($amountOfEnabledComputers -ne 0) {
         Write-Host "$DisOU contains enabled computer accounts" -ForegroundColor DarkYellow
     }
     #$listOfGPOs = $($data | Where-Object {$_.OU -eq $OU} | Select-Object GPOName).GPOName
     $listOfGPOs = (Get-GPInheritance -Target $DisOU).InheritedGpoLinks.DisplayName
     foreach ($gpo in $listOfGPOs) {
         [xml]$gpoReport = Get-GPOReport -Guid $(Get-GPO $gpo).Id -ReportType Xml
         if ($null -ne $gpoReport.GPO.User.ExtensionData) {
             Write-Host "$gpo has User Settings" -ForegroundColor Yellow
         }
     }
 }