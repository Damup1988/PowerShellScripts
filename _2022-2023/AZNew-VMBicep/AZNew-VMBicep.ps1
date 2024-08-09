$bicep = "C:\_bufer\_scripts\AZNew-VMBicep\VMB1MSEUN2.bicep"
Write-Host "Enter password for new vm:" -ForegroundColor Yellow
$password = Read-Host -AsSecureString
$vmName = "tempVM001"

New-AzResourceGroupDeployment `
    -Name "VMdeploy-$($vmName)-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName "RG-EUN-001" `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -vmName $vmName `
    -password $password `
    -vmSize "Standard_B1ms"