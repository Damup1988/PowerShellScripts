# Login to your Azure account
# Connect-AzAccount

# Define variables for your deployment
$rg = "RG-EUN-001"
$deploymentName = "vmDeploy-$(Get-Date -Format "dd.MM.yyyy.hh.mm.ss")"
$temaplte = "C:\_oneDrive\OneDrive\_Coding\_Projects\PowerShell\PSDamirSafarov\AZNew-VM\template.json"
$params = "C:\_oneDrive\OneDrive\_Coding\_Projects\PowerShell\PSDamirSafarov\AZNew-VM\parameters.json"

# Create a new deployment using the template and parameters files
New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg `
    -TemplateFile $temaplte `
    -TemplateParameterFile $params `
    -Verbose