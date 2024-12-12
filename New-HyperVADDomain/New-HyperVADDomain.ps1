function New-Domain ($name,$domain,$ipaddress,$preffix,$gateway,$dns,$vCPU,$RAMinGB,$gen) {
    $NewVMName = $name
    $VHDXFolder = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks"
    $VHDXFolderD = "E:\VMDisks"
    $SourceVHDXPath = "$VHDXFolder\IMAGEWS2022STDGEN1.vhdx"

    $NewComputerName = $name
    $DomainName = $domain
    $IPAddress = $ipaddress
    $PrefixLength = $preffix
    $DefaultGateway = $gateway
    $DNS1 = $dns
    $vCPU = $vCPU
    $RAMinGB = $RAMinGB
    $VMgen = $gen
    Write-Host "DomainName: $DomainName" -ForegroundColor Yellow
    Write-Host "domain: $domain" -ForegroundColor Yellow

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
        "Gateway: $DefaultGateway" >> "C:\_scripts\log.txt"
        "Domain: $DomainName" >> "C:\_scripts\log.txt"
        "Alias: $InterfaceAlias" >> "C:\_scripts\log.txt"
        "Line 38" >> "C:\_scripts\log.txt"
        $Error[0] >> "C:\_scripts\log.txt"
        New-VM `
            -Name $NewVMName `
            -MemoryStartupBytes ($RAMinBytes * 1Gb) `
            -VHDPath "$VHDXFolderD\$NewVMName.vhdx" `
            -SwitchName $DomainName `
            -Generation $VMgen
        "Line 46" >> "C:\_scripts\log.txt"
        $Error[0] >> "C:\_scripts\log.txt"
        Start-Sleep -Seconds 60
        Set-VMProcessor -VMName $NewVMName -Count $vCPU
        Start-VM -Name $NewVMName
        "Line 50" >> "C:\_scripts\log.txt"
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
            Param($IPAddress,$PrefixLength,$DefaultGateway,$NewVMName)
            $NICName = (Get-NetAdapter)[0].Name
            $DNS1 = "127.0.0.1"

            New-NetIPAddress `
                -InterfaceAlias $NICName `
                -IPAddress $IPAddress `
                -PrefixLength $PrefixLength `
                -DefaultGateway $DefaultGateway

            Set-DnsClientServerAddress `
                -InterfaceAlias $NICName `
                -ServerAddresses $DNS1

            Rename-Computer -NewName $NewVMName
            Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools

            Start-Sleep -Seconds 10
            Restart-Computer -Force
        } -ArgumentList $IPAddress,$PrefixLength,$DefaultGateway,$NewVMName
        Start-Sleep -Seconds 30

        Invoke-Command -VMName $NewVMName -Credential $Credential -ScriptBlock {
            param($DomainName)
            $DomainPassword = "BArakuda@123"
            $SecurePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
            Import-Module ADDSDeployment
            Install-ADDSForest `
            -CreateDnsDelegation:$false `
            -DatabasePath "C:\Windows\NTDS" `
            -DomainMode "WinThreshold" `
            -DomainName $DomainName `
            -DomainNetbiosName $DomainName.Split('.')[0] `
            -ForestMode "WinThreshold" `
            -InstallDns:$true `
            -LogPath "C:\Windows\NTDS" `
            -NoRebootOnCompletion:$false `
            -SysvolPath "C:\Windows\SYSVOL" `
            -Force:$true `
            -SafeModeAdministratorPassword $SecurePassword
            $Error[0] >> "C:\log.txt"
            Restart-Computer -Force
        } -ArgumentList $DomainName -Verbose
        "Line 111" >> "C:\_scripts\log.txt"
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

$DomainsToDeploy = Import-Csv -Path .\domains.csv -Delimiter ','
foreach ($vm in $DomainsToDeploy) {
    New-VMSwitch -Name $vm.Domain -SwitchType Internal
    $InterfaceAlias = (Get-NetAdapter | Where-Object {$_.Name -like "*$($vm.Domain)*"}).Name
    New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $vm.Gateway -PrefixLength $vm.Prefix
    New-Domain `
        -name $vm.Name `
        -domain $vm.Domain `
        -ipaddress $vm.IPAddress `
        -preffix $vm.Prefix `
        -gateway $vm.Gateway `
        -dns $vm.DNS `
        -vCPU $vm.vCPU `
        -RAMinGB $vm.RAMGB `
        -gen $vm.Gen
}