Connect-AzureAD

$allAADUsers = Get-AzureADUser -All $true

$user = $allAADUsers[0]
$damir = $allAADUsers | Where-Object {$_.Mail -eq "damir.safarov@petrofac.com"}

$email = $damir.Mail
$emplType # ???
$license = $damir.AssignedLicenses
$pwdLastSet #get from msol
$whenCreated = $damir.ExtensionProperty.createdDateTime
$dept = $damir.Department
$emplId = $damir.ExtensionProperty.employeeId
$title = $damir.JobTitle
$devision # ???
$upn = $damir.UserPrincipalName
$office = $damir.PhysicalDeliveryOfficeName
$lastLogon # get separatly
$pwdAge # #get from msol