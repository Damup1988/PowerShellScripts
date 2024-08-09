$rg = Get-AzResourceGroup -Name RG-EUN-PRD-RPA
$vm = Get-AzVM -Name RPA004PRDEUNAZR

Set-AzVMExtension -ExtensionName "Microsoft.Azure.Monitoring.DependencyAgent" `
    -ResourceGroupName RG-EUN-PRD-RPA `
    -VMName $vm.Name `
    -Publisher "Microsoft.Azure.Monitoring.DependencyAgent" `
    -ExtensionType "DependencyAgentWindows" `
    -TypeHandlerVersion 9.10 `
    -Location WestUS