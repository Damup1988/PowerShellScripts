Import-Module ActiveDirectory

# CONFIGURATION PART
# Specify destination path, AES key file for secure string and list of domain parameters
$destinationPathCRL = "C:\PKI\HTTP\crl\"
$destinationPathCRT = "C:\PKI\HTTP\crt\"
$pwFileKey = "C:\PKI\Scripts\credential.key"

$pkiDomains = @(
    # @("DC Base", "Domain Controller FQDN", "Service User Name", "Credential File"),
    @("DC=ipg,DC=corp", "ipgl-bu-srv004.emea.ipg.corp", "dehds@emea.ipg.corp", "C:\PKI\Scripts\svc-login1.txt"),
    @("DC=ipgphotonics,DC=com", "ipgl-bu-ad04.ipgphotonics.com", "ipgl-bu-caweb@ipgphotonics.com", "C:\PKI\Scripts\svc-login2.txt")
)

# SCRIPT PART
foreach($domain in $pkiDomains) {
    $dcbase = $domain[0]
    $server = $domain[1]

    if( Test-Path -Path $domain[3] -PathType Leaf ) {
        $password = Get-Content $domain[3] | ConvertTo-SecureString -Key (Get-Content $pwFileKey)
        $cred = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $domain[2], $password

        # Get Certificate Authority CDP
        $cdpList = Get-ADObject -Server $server -Credential $cred -LDAPFilter "(objectclass=cRLDistributionPoint)" -SearchBase "CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,${dcbase}" -Properties CN,certificateRevocationList,deltaRevocationList
        $cdpList | ForEach-Object {
            $cdpName = $_.CN
    
            # Output to file
            $_.certificateRevocationList  | Set-Content "${destinationPathCRL}${cdpName}.crl" -Encoding Byte
		
            # Check if delta exists
            if( $_.deltaRevocationList.Item(0).Length -gt 1 ) {
                # Output to file
                $_.deltaRevocationList  | Set-Content "${destinationPathCRL}${cdpName}+.crl" -Encoding Byte
            }
        }

        # Get Certificate Authority AIA
        $caObjArray = Get-ADObject  -Server $server -Credential $cred -LDAPFilter "(objectclass=certificationAuthority)" -SearchBase "CN=AIA,CN=Public Key Services,CN=Services,CN=Configuration,${dcbase}" -Properties cACertificate
        $caObjArray | ForEach-Object {
            $cahn = $_.Name
    
            $caCertArray = $_.cACertificate 
            $caCertNum = $caCertArray.Count - 1;
            $caCertArray | ForEach-Object {
                if( $caCertNum -ne 0 ) {
                    $_ | Set-Content "${destinationPathCRT}${cahn}(${caCertNum}).crt" -Encoding Byte
                } else {
                    $_ | Set-Content "${destinationPathCRT}${cahn}.crt" -Encoding Byte
                }
    
                $caCertNum--
            }
        }
    } else {
        Write-Host "Credential file $($domain[3]) not exist, skipping domain ${dcbase}"
    }
}