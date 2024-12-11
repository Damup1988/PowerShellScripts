function New-HVVM ($name,$domain,$ipaddress,$preffix,$gateway,$dns,$vCPU,$RAMinGB,$Image,$gen) {
    $NewVMName = $name
    $VHDXFolder = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks"
    $VHDXFolderD = "E:\VMDisks"
    if ($Image -eq "Win11") {
        $SourceVHDXPath = "$VHDXFolder\_IMAGEW11ENTGEN2.vhdx"
    }
    if ($Image -eq "Srv2022") {
        $SourceVHDXPath = "$VHDXFolder\IMAGEWS2022STDGEN1.vhdx"
    }

    $NewComputerName = $name
    $DomainName = $domain
    $IPAddress = $ipaddress
    $PrefixLength = $preffix
    $DefaultGateway = $gateway
    $DNS1 = $dns
    $vCPU = $vCPU
    $RAMinGB = $RAMinGB
    $VMgen = $gen

    $NewVMDisk = Copy-Item -Path $SourceVHDXPath -Destination "$VHDXFolderD\$NewVMName.vhdx"

    Start-Job -ScriptBlock {
        Param([string]$NewVMName,`
            [string]$VHDXFolderD,`
            [string]$IPAddress,`
            [Int32]$PrefixLength,`
            [string]$DefaultGateway,`
            [string]$DNS1,
            [string]$DomainName,
            [string]$NewComputerName,
            [Int32]$vCPU,
            [Int32]$RAMinGB,
            [Int16]$VMgen)
        $RAMinBytes = $RAMinGB
        "Generation: $VMgen" >> "C:\_scripts\log.txt"
        "RAM: $RAMinBytes" >> "C:\_scripts\log.txt"
        New-VM `
            -Name $NewVMName `
            -MemoryStartupBytes ($RAMinBytes * 1Gb) `
            -VHDPath "$VHDXFolderD\$NewVMName.vhdx" `
            -SwitchName $DomainName `
            -Generation $VMgen
        "Generation: $VMgen" >> "C:\_scripts\log.txt"
        $Error[0] >> "C:\_scripts\log.txt"
        Start-Sleep -Seconds 60
        Set-VMProcessor -VMName $NewVMName -Count $vCPU
        Start-VM -Name $NewVMName
        $Error[0] >> "C:\_scripts\log.txt"
        do {
            $state = (Get-VM $NewVMName).State
        } while (
            $state -eq "Off"
        )
        do {
            $state = (Get-VMIntegrationService -VMName $NewVMName | Where-Object Name -eq "Heartbeat").PrimaryStatusDescription
        } while (
            $state -ne "OK"
        )
        Start-Sleep -Seconds 60
        $userName = "Administrator"
        $password = "BArakuda@123"
        $SecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($userName, $SecurePassword)
        Invoke-Command -VMName $NewVMName -Credential $Credential -ScriptBlock {
            param($IPAddress,$NewComputerName,$DefaultGateway,$DomainName,$DNS1,$PrefixLength)
            $NICName = (Get-NetAdapter)[0].Name
            $InterfaceAlias = $NICName
            New-NetIPAddress `
                -InterfaceAlias $InterfaceAlias `
                -IPAddress $IPAddress `
                -PrefixLength $PrefixLength `
                -DefaultGateway $DefaultGateway
            $Error[0] >> "C:\log.txt"

            Set-DnsClientServerAddress `
                -InterfaceAlias $InterfaceAlias `
                -ServerAddresses $DNS1
            $Error[0] >> "C:\log.txt"

            $DomainUser = "dutyadmin"           # Specify the domain admin username
            $DomainPassword = "BArakuda@123"    # Specify the domain admin password
            $SecurePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($DomainUser, $SecurePassword)
            Start-Sleep -Seconds 10
            Add-Computer -NewName $NewComputerName -DomainName $DomainName -Credential $Credential
            $Error[0] >> "C:\log.txt"
            Restart-Computer -Force
        } -ArgumentList $IPAddress,$NewComputerName,$DefaultGateway,$DomainName,$DNS1,$PrefixLength -Verbose
        $Error[0] >> "C:\_scripts\log.txt"
    } -ArgumentList `
        $NewVMName,`
        $VHDXFolderD,`
        $IPAddress,`
        $PrefixLength,`
        $DefaultGateway,`
        $DNS1,`
        $DomainName,`
        $NewComputerName,`
        $vCPU,`
        $RAMinGB, `
        $VMgen
}

$VMsToDeploy = Import-Csv -Path .\deploy.csv -Delimiter ','
foreach ($vm in $VMsToDeploy) {
    New-HVVM `
        -name $vm.Name `
        -domain $vm.Domain `
        -ipaddress $vm.IPAddress `
        -preffix $vm.Prefix `
        -gateway $vm.Gateway `
        -dns $vm.DNS `
        -vCPU $vm.vCPU `
        -RAMinGB $vm.RAMGB `
        -Image $vm.Image `
        -gen $vm.Gen
}