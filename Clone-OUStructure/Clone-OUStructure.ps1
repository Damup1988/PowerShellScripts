# On a source domain DC
$rootSourceOU = "OU=SOURCECORP,DC=SOURCE,DC=local"
$allOUs = (Get-ADObject -SearchBase $rootSourceOU -Filter * | Where-Object {$_.ObjectClass -eq "organizationalUnit"}).DistinguishedName

$rootTargetOU = "OU=TARGETORGTEST,DC=TARGET,DC=local"

foreach ($ou in $allOUs) {
    if ($ou -ne $rootSourceOU) {
        $fullDN = $ou.Replace("$rootSourceOU", "$rootTargetOU")
        $Name = $fullDN.Split(',')[0].Replace("OU=","")
        $path = $fullDN.Replace("OU=$Name,", "")
        Write-Host "$Name;$path" -ForegroundColor Yellow
    }
}

# On a target domain DC
$OUs = Import-Csv -Path "C:\Users\dutyadmin\Documents\OUsToCreate.csv" -Delimiter ';'

foreach ($OU in $OUs) {
    New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path
}