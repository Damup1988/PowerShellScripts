[string] $nicName1 = "VM1-nic";

[string] $vmName1 = "VM1";

[string] $size = "Standard_D2s_v3";
[string] $imagePublisherName = "MicrosoftWindowsServer";
[string] $imageOffer = "WindowsServer";
[string] $imageSku = "2019-Datacenter";
[string] $imageVersion = "latest";

[string] $vnetName = "vnet001"
[string] $subnetName1 = "subnet001"

$resourceGroup = (Get-AzResourceGroup)[8];

$vnet1 = Get-AzVirtualNetwork -Name $vnetName

# Create virtual network cards
# VM1-nic
$subnetCfg1 = Get-AzVirtualNetworkSubnetConfig `
    -Name $subnetName1 `
    -VirtualNetwork $vnet1;

$nic1 = New-AzNetworkInterface `
    -Name $nicName1 `
    -Location $resourceGroup.Location `
    -ResourceGroupName $resourceGroup.ResourceGroupName `
    -SubnetId $subnetCfg1.Id

# Create virtual machines
# Credential
#$pw = $password | ConvertTo-SecureString -Force -AsPlainText;
#$credential = New-Object PSCredential($userName, $pw);

# VM1
$vmConfig1 = New-AzVMConfig `
    -VMName $vmName1 `
    -VMSize $size `
    | `
    Set-AzVMOperatingSystem `
        -Windows `
        -ComputerName $vmName1 `
        -Credential $credential `
    | `
    Set-AzVMSourceImage `
          -PublisherName $imagePublisherName `
          -Offer $imageOffer `
          -Sku $imageSku `
          -Version $imageVersion `
    | `
    Set-AzVMBootDiagnostic `
        -Enable `
        -ResourceGroupName $resourceGroup.ResourceGroupName `
    | `
    Add-AzVMNetworkInterface -Id $nic1.Id;

New-AzVM `
    -VM $vmConfig1 `
    -Location $resourceGroup.Location `
    -ResourceGroupName $resourceGroup.ResourceGroupName;