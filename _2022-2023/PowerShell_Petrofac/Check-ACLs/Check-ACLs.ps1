$sharePath = "\\fil002prdeunazr\abzdata\PTBS_Archive"

#$allFiles = Get-ChildItem -Path $sharePath -Recurse
$allFilesPaths = Get-Content -Path "C:\Users\virp_damrov\Documents\Scripts\Assign-ACLs\allFilesPaths.txt"

$allFilesPaths.Count

$accessGranted = 0
$accessNotGranted = 0
$counter = 0
foreach ($filePath in $allFilesPaths) {
    $counter++
    Write-Progress -Activity "Checking the access" -CurrentOperation $filePath -PercentComplete (($counter / $allFilesPaths.Count) * 100)
    $acls = $(Get-Acl -Path $filePath).Access.IdentityReference.Value
    if ($acls.Contains("DSPETROFAC\GG-ACL-ABZ-PTBS-Archive-Read")) {
        $accessGranted++
    }
    else {
        $accessNotGranted++
    }
}

Write-Host "Count of files where the access is granted: $($accessGranted)" -ForegroundColor Yellow
Write-Host "Cound of files where the access is not granted: $($accessNotGranted)" -ForegroundColor Blue