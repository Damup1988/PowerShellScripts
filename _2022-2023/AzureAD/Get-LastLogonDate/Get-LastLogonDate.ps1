Connect-AzureAD
$upns = Get-Content -Path "C:\_bufer\_scripts\AzureAD\Get-LastLogonDate\users.txt"
$out = "C:\_bufer\_scripts\AzureAD\Get-LastLogonDate\out.txt"
$total = $upns.Count
$total
$current = 0
foreach ($upn in $upns) {
    $current++
    Write-Progress -Activity 'Processing computers' -CurrentOperation $upn -PercentComplete (($current / $total) * 100)    
    write-host "Doung $current - $upn" -foregroundcolor yellow
    $user = $upn
    try {
        Start-Sleep -Milliseconds 1200
        $logs = (Get-AzureADAuditSignInLogs -Filter "startsWith(userPrincipalName,'$($upn)')" -Top 1).CreatedDateTime
        if ($null -ne $logs) {
            $date = $logs
            $logs = $null
        }
    }
    catch {
        $Error.ToString()
        $date = "ERROR"
    }   
    "$($user);$($date)" >> $out
}