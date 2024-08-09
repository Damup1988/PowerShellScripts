$allMailBoxes = Get-MailBox -ResultSize Unlimited

$total = $allMailBoxes.Count
Write-Host "Total files: $($total)"
$current = 0

$result = @()
foreach ($box in $allMailBoxes) {
    $current++
    Write-Progress `
        -Activity "Processing all boxes" `
        -CurrentOperation $box.UserPrincipalName `
        -PercentComplete (($current / $total) * 100)
    
    $acls = Get-MailboxPermission -Identity $box.UserPrincipalName
    foreach ($acl in $acls) {
        if ($acl.User -ne "NT AUTHORITY\SELF") {
            $result += "$($box.UserPrincipalName);$($acl.User);$($acl.AccessRights)"
        }
    }
    $aclsSendAs = Get-EXORecipientPermission -Identity $box.UserPrincipalName
    foreach ($acl in $aclsSendAs) {
        if ($acl.Trustee -ne "NT AUTHORITY\SELF") {
            $result += "$($box.UserPrincipalName);$($acl.Trustee);Send as"
        }
    }
    $aclsSendOnBehalf = (Get-EXOMailbox -Identity $box.UserPrincipalName -Properties GrantSendOnBehalfTo).GrantSendOnBehalfTo
    foreach ($acl in $aclsSendOnBehalf) {
        $result += "$($box.UserPrincipalName);$acl;Send on behalf"
    }
}