Import-Module PSPKI

$availableTemplates = certutil -CATemplates | ForEach-Object {$_.split(":")[0]} | Where-Object {$_ -ne "Certutil"}
$todayDate = Get-Date -Format "MM.dd.yyyy.HH.mm.ss"

$data = @()
foreach ($at in $availableTemplates) {
    $t = Get-CertificateTemplate -Name $at 
    $name = $t.Name
    $displayName = $t.DisplayName
    $autoEnrollemnt = $t.AutoenrollmentAllowed
    $validityPeriod = $t.Settings.ValidityPeriod
    $renewalPeriod = $t.Settings.RenewalPeriod
    $purposes = @()
    $t.Settings.EnhancedKeyUsage | ForEach-Object {$purposes += $_.FriendlyName}
    $keyUsages = $purposes -join "|"
    $algos = @()
    $t.Settings.Cryptography.KeyAlgorithm | ForEach-Object {$algos += $_.FriendlyName}
    $cryptKeyAlgorithm = $algos -join "|"
    $cryptMinimalKeyLength = $t.Settings.Cryptography.MinimalKeyLength

    $myPsObject = New-Object -TypeName PsObject
    $myPsObject | Add-Member -MemberType NoteProperty -Name "name" -Value $name
    $myPsObject | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $displayName
    $myPsObject | Add-Member -MemberType NoteProperty -Name "autoEnrollemnt" -Value $autoEnrollemnt
    $myPsObject | Add-Member -MemberType NoteProperty -Name "validityPeriod" -Value $validityPeriod
    $myPsObject | Add-Member -MemberType NoteProperty -Name "renewalPeriod" -Value $renewalPeriod
    $myPsObject | Add-Member -MemberType NoteProperty -Name "keyUsages" -Value $keyUsages
    $myPsObject | Add-Member -MemberType NoteProperty -Name "cryptKeyAlgorithm" -Value $cryptKeyAlgorithm
    $myPsObject | Add-Member -MemberType NoteProperty -Name "cryptMinimalKeyLength" -Value $cryptMinimalKeyLength
        
    $data += $myPsObject
}

if (Test-Path "C:\temp") {
    $data | Export-Csv -Path "C:\Temp\ListOfTemplates$($todayDate).csv" -Delimiter ";" -NoTypeInformation
}
else {
    New-Item -Name "Temp" -Path "C:\" -ItemType Directory
    $data | Export-Csv -Path "C:\Temp\ListOfTemplates$($todayDate).csv" -Delimiter ";" -NoTypeInformation
}