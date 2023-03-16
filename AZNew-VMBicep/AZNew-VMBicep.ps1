$bicep = "C:\_bufer\_scripts\PowerShellDamirSafarov\AZNew-VMBicep\VMB1MSEUN2.bicep"
$password = Read-Host -AsSecureString

New-AzResourceGroupDeployment `
    -Name "VMdeploy-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName "RG-EUN-001" `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -vmName "vm010eunaz" `
    -password $password `
    -vmSize "Standard_DS3_v2"