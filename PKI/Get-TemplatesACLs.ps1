Import-Module PSPKI
$availableTemplates = certutil -CATemplates | ForEach-Object {$_.split(":")[0]} | Where-Object {$_ -ne "Certutil"}
$todayDate = Get-Date -Format "MM.dd.yyyy.HH.mm.ss"
if (Test-Path "C:\temp") {
    $resultFile = New-Item -Path "C:\Temp" -Name "ListOfTemplates$($todayDate).txt" -ItemType File
}
else {
    New-Item -Name "Temp" -Path "C:\" -ItemType Directory
    $resultFile = New-Item -Path "C:\Temp" -Name "ListOfTemplates$($todayDate).txt" -ItemType File
}

foreach ($at in $availableTemplates) {
    $t = Get-CertificateTemplate -Name $at
    $templateName = $t.Name
    $template = Get-CertificateTemplate -Name $templateName
    $ACLs = (Get-CertificateTemplateAcl -Template $template).Access
    $out = @()
    foreach ($acl in $ACLs) {
        $identity = $acl.IdentityReference
        $controlType = $acl.AccessControlType
        $permissions = $acl.Rights
        $result = "$identity|$controlType|$permissions"
        $out += $result
    }
    $templateName >> $resultFile.FullName
    "++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $resultFile.FullName
    $out                                                       >> $resultFile.FullName
    "________________________________________________________" >> $resultFile.FullName
}