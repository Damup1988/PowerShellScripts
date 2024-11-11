$server = "ipgphotonics.com"
$allEMEAobjects = Get-ADObject -Filter * -SearchBase "OU=CIS,DC=ipgphotonics,DC=com" -Properties * -Server $server

$data = @()
$i = 0
foreach ($obj in $allEMEAobjects) {
    $i++
    Write-Progress -Activity "Processing items..." -Status "Item $i of $($allEMEAobjects.Count))" -PercentComplete (($i / $allEMEAobjects.Count) * 100)
    if ($obj.memberof.count -eq 0) {
        $memberof = "NONE"
    }
    else {
        $memberof = ($obj.memberof | ForEach-Object {$_.split(',')[0].Replace('CN=','')}) -join '|'
    }
    if ($obj.member.count -eq 0) {
        $members = "NONE"
    }
    else {
        $members = ($obj.member | ForEach-Object {$_.split(',')[0].Replace('CN=','')}) -join '|'
    }
    $OU = $obj.DistinguishedName.Replace("CN=$($obj.Name),","")

    $MyPSCustomObj = New-Object -TypeName PSObject
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Object Class" -Value $obj.ObjectClass
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Name" -Value $obj.Name
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Distinguished Name" -Value $obj.DistinguishedName
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "When Created" -Value $obj.whenCreated
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "When Changed" -Value $obj.whenChanged
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OU" -Value $OU
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "memberof" -Value $memberof
    $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "members" -Value $members
    switch ($obj.ObjectClass) {
        "computer" {
            $client = Get-ADComputer $obj.sAMAccountName -Properties OperatingSystemVersion,memberof,DistinguishedName -Server $server

            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $client.Enabled
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value $client.OperatingSystemVersion
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value $obj.sAMAccountName
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "user" {
            $user = Get-ADUser $obj.sAMAccountName -Properties memberof,DistinguishedName -Server $server

            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $user.Enabled
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value $user.UserPrincipalName
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value $($obj.proxyAddresses -join '|')
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value $obj.sAMAccountName
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value $obj.targetAddress
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "contact" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value $($obj.proxyAddresses -join '|')
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value $obj.targetAddress
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value $obj.mail
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value $obj.mailNickname
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "group" {
            $adGroup = Get-ADGroup $obj.name -Server $server

            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value $($obj.proxyAddresses -join '|')
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value $obj.mail
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value $adGroup.GroupCategory
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value $adGroup.GroupScope
        }
        "msExchDynamicDistributionList" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value $($obj.proxyAddresses -join '|')
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value $obj.mail
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value $obj.mailNickname
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "organizationalUnit" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "printQueue" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "rRASAdministrationConnectionPoint" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "serviceConnectionPoint" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
        "volume" {
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "OS" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "ProxyAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "samaccountname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "targetAddress" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mail" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "mailNickname" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value "Not applicable"
            $MyPSCustomObj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value "Not applicable"
        }
    }

    $data += $MyPSCustomObj
}