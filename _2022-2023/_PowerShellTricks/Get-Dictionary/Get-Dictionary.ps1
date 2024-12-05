function Change-DictValue ([ref]$value1,[ref]$value2) {
    $value1.Value++
    $value2.Value--
}

$myDictionray = @{
    "key1" = @(13,22)
    "key2" = @(44,55)
    "key3" = @(52,67)
}

$temp1 = $myDictionray["key2"][0]
$temp2 = $myDictionray["key2"][1]

Change-DictValue -value1 ([ref]$temp1) -value2 ([ref]$temp2)

$myDictionray["key2"][0] = $temp1
$myDictionray["key2"][1] = $temp2

$myDictionray