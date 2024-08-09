function Delete-NetDrive ($netDrives) {
    foreach ($tempDrive in $netDrives) {
        Write-host "Deleting drive $($tempDrive.localpath) ($($tempDrive.RemotePath))"        
        Remove-SmbMapping -RemotePath $tempDrive.RemotePath -Force
    }
}

<#$TempPath = [System.IO.Path]::GetTempPath()
Start-Transcript -Path "$($TempPath)GBRDriveFix.log" -Append

$AllDrives1 = Get-SmbMapping

$Srv001bbbDrives = $AllDrives1 | Where-Object {$_.RemotePath -match "srv001bbbabzgbr"}
$Fil001bbbDrives = $AllDrives1 | Where-Object {$_.RemotePath -match "fil001bbbabzgbr"}
$Fil001Drives = $AllDrives1 | Where-Object {$_.RemotePath -match "fil001abzgbr"}

foreach ($tempDrive in $Srv001bbbDrives) {
	Write-host "Deleting drive $($tempDrive.localpath) ($($tempDrive.RemotePath))"
	net use "$($tempDrive.localpath)" /delete
}

foreach ($tempDrive in $Fil001bbbDrives) {
	Write-host "Deleting drive $($tempDrive.localpath) ($($tempDrive.RemotePath))"
	net use "$($tempDrive.localpath)" /delete
}

foreach ($tempDrive in $Fil001Drives) {
	Write-host "Deleting drive $($tempDrive.localpath) ($($tempDrive.RemotePath))"
	net use "$($tempDrive.localpath)" /delete
}

Stop-Transcript

exit#>

$TempPath = [System.IO.Path]::GetTempPath()
Start-Transcript -Path "$($TempPath)GBRDriveFix.log" -Append

$AllDrives1 = Get-SmbMapping

$Srv001bbbDrives = $AllDrives1 | Where-Object {$_.RemotePath -match "srv001bbbabzgbr"}
$Fil001bbbDrives = $AllDrives1 | Where-Object {$_.RemotePath -match "fil001bbbabzgbr"}
$Fil001Drives = $AllDrives1 | Where-Object {$_.RemotePath -match "fil001abzgbr"}

Delete-NetDrive -netDrives $Srv001bbbDrives
Delete-NetDrive -netDrives $Fil001bbbDrives
Delete-NetDrive -netDrives $Fil001Drives

Stop-Transcript

exit