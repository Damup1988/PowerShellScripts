# onprem part

# attribute value, e.g. "tel:+97165173057;ext=73057"
$newLine = "" # tel:+97165173057;ext=73057
$userEmail = "" # damir.safarov@petrofac.com
$user = Get-ADUser -Filter {UserPrincipalName -eq $userEmail}

Set-ADUser $user -Replace @{"msRTCSIP-Line" = $newLine}