Import-Module ActiveDirectory

# CONFIGURATION PART
# Specify destination path
$destinationPathCRL = "C:\PKI\crl"
$destinationPathCRT = "C:\PKI\crt"
$rootCAHostName = "ContadaRootCA"
$configFilePath = "C:\PKI\script\config.json"

$config = Get-Content -Path $configFilePath | ConvertFrom-Json
# CDP part
$CDPList = Get-ADObject `
    -Server $config.FQDN `
    -LDAPFilter "(objectclass=crlDistributionPoint)" `
    -SearchBase "CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,$($config.DN)" `
    -Properties CN,certificateRevocationList,deltaRevocationList

foreach ($cdp in $CDPList) {
    $cdp.certificateRevocationList | Set-Content "$($destinationPathCRL)\$($cdp.CN).crl" -Encoding Byte
    $cdp.deltaRevocationList | Set-Content "$($destinationPathCRL)\$($cdp.CN)+.crl" -Encoding Byte
}

# IAI part
$IAIlist = Get-ADObject `
    -Server $config.FQDN `
    -LDAPFilter "(objectclass=certificationAuthority)" `
    -SearchBase "CN=AIA,CN=Public Key Services,CN=Services,CN=Configuration,$($config.DN)" `
    -Properties caCertificate

foreach ($IAI in $IAIlist) {
    $certs = $IAI.caCertificate
    foreach ($cert in $certs) {
        $caFQDN = (Get-ADObject `
            -Server $config.FQDN `
            -Filter * `
            -Properties dnsHostName `
            -SearchBase "CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,$($config.DN)" `
            | Where-Object {$_.Name -eq $IAI.Name}).dnsHostName
            
        if ($IAI.name -like "*root*") {
            $cert | Set-Content "$($destinationPathCRT)\$($rootCAHostName)_$($IAI.Name).crt" -Encoding Byte
        }
        else {
            $cert | Set-Content "$($destinationPathCRT)\$($caFQDN)_$($IAI.Name).crt" -Encoding Byte
        }
    }
}
