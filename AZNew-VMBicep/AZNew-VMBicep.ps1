$bicep = "C:\_bufer\_scripts\PowerShellDamirSafarov\AZNew-VMBicep\VMB1MSEUN2.bicep"
$password = Read-Host -AsSecureString
$vmName = ""

New-AzResourceGroupDeployment `
    -Name "VMdeploy-$($vmName)-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName "RG-EUN-001" `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -vmName $vmName `
    -password $password `
    -vmSize "Standard_DS3_v2"