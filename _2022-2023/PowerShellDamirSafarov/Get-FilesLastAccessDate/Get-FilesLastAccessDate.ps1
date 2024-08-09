$paths = $(Get-ChildItem -Path "w:\" | Where-Object {$_.Mode -like "d*"} | Select-Object FullName).FullName

$report = New-Item `
    -Name "report_$(Get-Date -Format "dd.MM.yyyy.hh.mm.ss").txt" `
    -Path "C:\Scripts\Get-FilesModifiedDate"
"FileType;Name;Path;LastWriteTime;LastAccessTime;FileSize" > $report.FullName

$count = 0
foreach($path in $paths) {
    $count++
    Write-Progress -Activity "Checking $($path)" -PercentComplete (($count / $paths.Count) * 100)
    $allFiles = Get-ChildItem -Path $path -Recurse -Verbose

    $count1 = 0
    foreach($file in $allFiles) {
        $count1++
        Write-Progress -Activity "Checking $($file)" -PercentComplete (($count1 / $allFiles.Count) * 100)        
        if($file.Mode -like "d*") {
            $fileType = "Folder"
            $size = "0"
        }
        else {
            $fileType = "File"
            $size = $file.Length
        }
        $fileNmae = $file.Name
        $filePath = $file.FullName
        $LastWriteTime = $file.LastWriteTime.ToString("dd.MM.yyyy")
        $LastAccessTime = $file.LastAccessTime.ToString("dd.MM.yyyy")
        "$($fileType);$($fileNmae);$($filePath);$($LastWriteTime);$($LastAccessTime);$($size)" >> $report
    }
}