$ca = Get-CA -ComputerName "ACA01.adatum.local"
$allCerts = Get-IssuedRequest -CertificationAuthority $ca | Where-Object {$_.NotAfter -ge $(Get-Date)}

$data = @()
foreach ($c in $allCerts) {
    $myPsObject = New-Object -TypeName PsObject
    $myPsObject | Add-Member -MemberType NoteProperty -Name "RequestID" -Value $c.RequestID
    $myPsObject | Add-Member -MemberType NoteProperty -Name "RequesterName" -Value $c.'Request.RequesterName'
    $myPsObject | Add-Member -MemberType NoteProperty -Name "CommonName" -Value $c.CommonName
    $myPsObject | Add-Member -MemberType NoteProperty -Name "NotBefore" -Value $c.NotBefore
    $myPsObject | Add-Member -MemberType NoteProperty -Name "NotAfter" -Value $c.NotAfter
    $myPsObject | Add-Member -MemberType NoteProperty -Name "SerialNumber" -Value $c.SerialNumber
    $myPsObject | Add-Member -MemberType NoteProperty -Name "CertificateTemplate" -Value $c.CertificateTemplateOid.FriendlyName

    $data += $myPsObject
}

$todayDate = Get-Date -Format "MM.dd.yyyy.HH.mm.ss"
if (Test-Path "C:\temp") {
    $data | Export-Csv -Path "c:\temp\validCertificates$($todayDate).csv" -Delimiter ';' -NoTypeInformation
}
else {
    New-Item -Name "Temp" -Path "C:\" -ItemType Directory
    $data | Export-Csv -Path "c:\temp\validCertificates$($todayDate).csv" -Delimiter ';' -NoTypeInformation
}