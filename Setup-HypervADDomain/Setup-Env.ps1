# Create internal virtual switch
$switchName = "AWESOME"
New-VMSwitch -Name $switchName -SwitchType Internal
New-NetIPAddress -InterfaceAlias "vEthernet $switchName" -IPAddress 10.0.10.1 -PrefixLength 24


# Win Server 2022 Std
$NewVMName = "VM10"
$VHDXFolder = "D:\_VMs"
$SourceVHDXPath = "$VHDXFolder\IMAGEWS2022STDGEN1.vhdx"
$NewVMDisk = Copy-Item -Path $SourceVHDXPath -Destination "$VHDXFolder\$NewVMName.vhdx"
New-VM `
    -Name $NewVMName `
    -MemoryStartupBytes 1Gb `
    -VHDPath "$VHDXFolder\$NewVMName.vhdx" `
    -SwitchName $switchName


# W11 Pro
$NewVMName = "VM8"
$VHDXFolder = "D:\_VMs"
$SourceVHDXPath = "$VHDXFolder\_IMAGEW11ENTGEN2.vhdx"
$NewVMDisk = Copy-Item -Path $SourceVHDXPath -Destination "$VHDXFolder\$NewVMName.vhdx"
New-VM -Name $NewVMName -Generation 2 -MemoryStartupBytes 2Gb -VHDPath "$VHDXFolder\$NewVMName.vhdx"