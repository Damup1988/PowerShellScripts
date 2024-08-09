Start-Transcript
# Install-Module -Name Exchangeonlinemanagement -Scope CurrentUser
# Import-Module -Name Exchangeonlinemanagement 
Connect-IPPSSession
# FormatEnumerationLimit=-1
Get-ActivityAlert -Identity "ediscovery Alert" | FL
Get-ProtectionAlert -Identity "ediscovery Alert" | FL
#(Run this for 2-3 activities)
Stop-Transcript