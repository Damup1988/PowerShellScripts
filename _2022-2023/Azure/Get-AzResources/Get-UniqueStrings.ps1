# Specify the path to your text file
$filePath = "C:\_bufer\_scripts\Azure\Get-AzResources\123.txt"

# Read the content of the file
$stringArray = Get-Content $filePath

# Create an empty hashtable to track unique values
$uniqueValuesTable = @{}

$newArray = @()
# Loop through each string in the array
foreach ($string in $stringArray) {
    # Check if the string is already in the hashtable
    if (-not $uniqueValuesTable.ContainsKey($string)) {
        # If not, add it to the hashtable and output it
        $uniqueValuesTable[$string] = $true
        Write-Output $string
        #$newArray += $string
        $string >> .\newArray.txt
    }
}