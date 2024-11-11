$filesToMerge = Get-ChildItem -Path .\ | Where-Object {$_.Name -like "*.txt"}
$totalFiles = $filesToMerge.Count

$i = 0
$data = @()
foreach ($f in $filesToMerge) {
    #$content1 = Get-Content -Path $f.FullName
    $content1 = Get-Content -Path $filesToMerge[$i+1].FullName
    $data += $content1
    $content2 = Get-Content -Path $filesToMerge[$i+2].FullName
    $compareResult = Compare-Object -ReferenceObject $content1 -DifferenceObject $content2
    foreach ($r in $compareResult) {
        if ($r.SideIndicator -eq "=>") {
            $data += $r.InputObject
        }
    }
}