# Replace "C:\example\directory" with the path to the directory you want to list
$rootPath = "C:\_bufer"

# Create a CSV file to output the results to
$outputFile = "C:\_bufer\SizeReport\SizeReport3.csv"
"Type;FullPath;Size" | Out-File $outputFile -Encoding UTF8

# Recursively list all folders and files under the root path, including hidden items
$items = Get-ChildItem $rootPath -Recurse -Force
$total = $items.Count
$i = 0

# Loop through each item and output its information to the CSV file
foreach ($item in $items) {
    # Determine whether the current item is a folder or a file
    $type = If($item.PsIsContainer){ "Folder" } Else { "File" }
    
    # Output the item's full path and size in bytes for both files and folders
    if ($type -eq "File") {
        $size = "{0:N0} bytes" -f $item.Length
    } else {
        $childItems = Get-ChildItem -Recurse -Force $item.FullName
        if ($childItems) {
            $size = "{0:N0} bytes" -f ($childItems | Measure-Object -Property Length -Sum).Sum
        } else {
            $size = "0 bytes"
        }
    }
    $path = $item.FullName
    
    # Output the item's information to the CSV file
    "$type;$path;$size" | Out-File $outputFile -Encoding UTF8 -Append
    
    # Update the progress bar
    $i++
    Write-Progress -Activity "Processing items..." -Status "Item $i of $total" -PercentComplete (($i / $total) * 100)
}