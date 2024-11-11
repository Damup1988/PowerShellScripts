$allGPOs = Get-GPO -All
$rootOU = "ipgphotonics.com/EMEA"
$2ndOU = "ipgphotonics.com/CIS"

$data = @()
$i = 0
foreach ($gpo in $allGPOs) {
    $i++
    Write-Progress `
        -Activity "Processing group...$($gpo.DisplayName))" `
        -Status "Item $i of $($allGPOs.Count)" -PercentComplete (($i / $allGPOs.Count) * 100)
    [xml]$gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml

    if ((($gpoReport.gpo.Computer.ExtensionData.Extension `
        | Where-Object {$_.Policy -ne $null}).Policy `
        | Where-Object {$_.name -like "*loopback*"}).State -eq "Enabled")
        {
        $loopBackState = "Enabled"
    }
    else {
        $loopBackState = "Disabled"
    }

    $OUlist = $gpoReport.gpo.LinksTo.SOMPath -join ';'
    $OUsCount = $OUlist.Split(';').Count
    $counter = 0
    foreach ($OU in $OUlist.Split(';')) {
        if ($OU -like "$rootOU*") {
            $counter++
        }
    }
    if ($OUsCount -eq $counter) {
        Write-Host "$($gpo.DisplayName) assigned only to $rootOU"
        $emeaOnlyAssigned = "True"
    }
    else {
        $emeaOnlyAssigned = "False"
    }
    foreach ($OU in $OUlist.Split(';')) {
        if ($OU -like "$rootOU*" -or $OU -like "$2ndOU*") {
            $permissions = Get-GPPermission -Guid $gpo.Id -All
            $permissionsArray = @()
            foreach ($p in $permissions) {
                $permissionsArray += "$($p.Trustee.Name)@$($p.Permission)"
            }

            Write-Host "$($gpo.DisplayName)" -ForegroundColor Yellow
            $MyPSCustomObj = New-Object -TypeName PSObject
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Name" -Value $gpo.DisplayName
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "guid" -Value $gpo.Id
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OU" -Value $OU
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "User" -Value $gpoReport.gpo.User.Enabled
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Computer" -Value $gpoReport.gpo.Computer.Enabled
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "LoopBack" -Value $loopBackState
            if ($null -ne $gpoReport.gpo.User.ExtensionData) {
                $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UserSettings" -Value "NotEmpty"
            }
            else {
                $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UserSettings" -Value "Empty"
            }
            if ($null -ne $gpoReport.gpo.Computer.ExtensionData) {
                $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ComputerSettings" -Value "NotEmpty"
            }
            else {
                $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ComputerSettings" -Value "Empty"
            }
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "EmeaOnly" -Value $emeaOnlyAssigned
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Delegation" -Value $($permissionsArray -join "|")
            $data += $MyPSCustomObj
        }
    }
}

$data | Export-Csv -Path .\GpoReport25.03.2024.csv -NoTypeInformation -Delimiter ';'