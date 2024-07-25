$pkiDomains = @(
    # @("DC Base", "Domain Controller FQDN", "Service User Name", "Credential File"),
    @("DC=ipg,DC=corp", "ipgl-bu-srv004.emea.ipg.corp", "dehds@emea.ipg.corp", "C:\PKI\Scripts\svc-login1.txt"),
    @("DC=ipgphotonics,DC=com", "ipgl-bu-ad04.ipgphotonics.com", "ipgl-bu-caweb@ipgphotonics.com", "C:\PKI\Scripts\svc-login2.txt")
)

foreach ($domain in $pkiDomains) {
    Get-Content $domain[3] | ConvertTo-SecureString -Key (Get-Content $pwFileKey)
}