# Specify the path to your input CSV file
$inputFilePath = "C:\_bufer\testInput.csv"

# Specify the path for the output CSV file
$outputFilePath = "C:\_bufer\_scripts\Azure\Get-AzResources\Out2.csv"

# Read the CSV file
$data = Import-Csv -Path $inputFilePath -Delimiter ';'

# Define a function to extract key-value pairs from Tags column
function Get-Tags($tags) {
    $tagPairs = $tags -split ','
    $tagValues = @{}

    foreach ($pair in $tagPairs) {
        $key, $value = $pair -split '@', 2
        if ($key -ne $null -and $key -ne '') {
            $tagValues[$key] = $value
        }
    }

    return $tagValues
}

# Create an array to store the results
$resultArray = @()

# Process the data and create a new array of objects
foreach ($entry in $data) {
    $tagValues = Get-Tags $entry.Tags

    $propsObj = [PSCustomObject]$entry.PSObject.Properties | ForEach-Object {
        $_.Name, $_.Value
    }

    if ($tagValues) {
        $tagValues.GetEnumerator() | ForEach-Object {
            $propsObj | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value
        }
    }

    # Add the object to the result array
    $resultArray += $propsObj
}

# Export the new data to a new CSV file
$resultArray | Export-Csv -Path $outputFilePath -Delimiter ';' -NoTypeInformation