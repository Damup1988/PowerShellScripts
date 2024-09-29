# Create internal virtual switch
$switchName = "AWESOME"
New-VMSwitch -Name $switchName -SwitchType Internal
New-NetIPAddress -InterfaceAlias "vEthernet $switchName" -IPAddress 10.0.10.1 -PrefixLength 24


# Win Server 2022 Std
$NewVMName = "VM11"
$VHDXFolder = "D:\_VMs"
$SourceVHDXPath = "$VHDXFolder\IMAGEWS2022STDGEN1.vhdx"
$NewVMDisk = Copy-Item -Path $SourceVHDXPath -Destination "$VHDXFolder\$NewVMName.vhdx"
New-VM `
    -Name $NewVMName `
    -MemoryStartupBytes 2Gb `
    -VHDPath "$VHDXFolder\$NewVMName.vhdx" `
    -SwitchName $switchName

# Win Server 2022 Std Gen2
$NewVMName = "VM12"
$VHDXFolder = "D:\_VMs"
$SourceVHDXPath = "$VHDXFolder\IMAGEWS2022STDGEN1.vhdx"
$NewVMDisk = Copy-Item -Path $SourceVHDXPath -Destination "$VHDXFolder\$NewVMName.vhdx"
New-VM `
    -Name $NewVMName `
    -MemoryStartupBytes 2Gb `
    -VHDPath "$VHDXFolder\$NewVMName.vhdx" `
    -SwitchName $switchName `
    -Generation 2

# W11 Pro
$NewVMName = "VM8"
$VHDXFolder = "D:\_VMs"
$SourceVHDXPath = "$VHDXFolder\_IMAGEW11ENTGEN2.vhdx"
$NewVMDisk = Copy-Item -Path $SourceVHDXPath -Destination "$VHDXFolder\$NewVMName.vhdx"
New-VM `
    -Name $NewVMName `
    -Generation 2 `
    -MemoryStartupBytes 2Gb `
    -VHDPath "$VHDXFolder\$NewVMName.vhdx"