$bicep = "C:\_oneDrive\OneDrive\_Coding\_Projects\PowerShell\PSDamirSafarov\AZNew-VMBicep\VMB1MSEUN2.bicep"
$password = Read-Host -AsSecureString

New-AzResourceGroupDeployment `
    -Name "VMdeploy-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName "RG-EUN-001" `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -vmName "vm003eunaz" `
    -password $password `
    -vmSize "Standard_B1ms"