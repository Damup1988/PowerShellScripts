$users = Get-Content -Path "C:\_bufer\_scripts\AzureAD\Set-Property\usersToUpdate.txt"
$log = "C:\_bufer\_scripts\AzureAD\Set-Property\log.txt"

foreach ($userId in $users) {
    $user = Get-AzureADUser -ObjectId $userId | Select-Object mail
    $currentMailAddress = $user.mail
    $newMailAddress = $currentMailAddress.Replace("WWEnergyServices.onmicrosoft.com", "wandwenergy.com")
    $params = New-Object System.Collections.Generic.Dictionary"[String,String]"
    $params.Add("mail", "$($newMailAddress)")
    Set-AzureADUser -ObjectId $userId -ExtensionProperty $params
    "oldEmailAddress;$($currentMailAddress)|newEmailAddress;$($newMailAddress)" >> $log
}