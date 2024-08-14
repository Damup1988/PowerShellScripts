$allIssuedCertificatesCsv = certutil -out "Certificate Expiration Date,Certificate Effective Date,Certificate Template,Requester Name,Issued Common Name,Issued Email Address" -view csv
$allIssuedCertificates = $allIssuedCertificatesCsv | ConvertFrom-Csv
$validCertificates = $allIssuedCertificates `
    | Where-Object {$_.'Certificate Expiration Date' -ne "EMPTY"} `
    | Where-Object {[datetime]$_.'Certificate Expiration Date' -gt (Get-Date)}
$todayDate = Get-Date -Format "MM.dd.yyyy.HH.mm.ss"
if (Test-Path "C:\temp") {
    $validCertificates | Export-Csv -Path "c:\temp\validCertificates$($todayDate).csv" -Delimiter ';' -NoTypeInformation
}
else {
    New-Item -Name "Temp" -Path "C:\" -ItemType Directory
    $validCertificates | Export-Csv -Path "c:\temp\validCertificates$($todayDate).csv" -Delimiter ';' -NoTypeInformation
}