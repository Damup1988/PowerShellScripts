$scriptBlock = {
    Set-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" `
    -Name 'KeyManagementServiceName' `
    -Value 'myKMS.contoso.local'
    cd "C:\Program Files (x86)\Microsoft Office\Office16"
    cscript ospp.vbs /actype:2
    cscript ospp.vbs /inpkey:XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
    cscript ospp.vbs /act
    Start-Sleep -Seconds 20
    Set-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" `
    -Name 'KeyManagementServiceName' `
    -Value 'azkms.core.windows.net'
}

$AVDhosts = @()

foreach ($AVDhost in $AVDhosts) {
    Invoke-Command -ComputerName $AVDhost -ScriptBlock $scriptBlock
}