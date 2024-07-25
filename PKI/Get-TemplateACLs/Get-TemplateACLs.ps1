$templateName = "WebServer"
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
Write-Host "$templateName" -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow
$out