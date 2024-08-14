$todayDate = Get-Date -Format "MM.dd.yyyy.HH.mm.ss"
if (Test-Path "C:\temp") {
    $AIAFile = New-Item -Path "C:\Temp" -Name "AIA_$($todayDate).txt" -ItemType File
    $CDPFile = New-Item -Path "C:\Temp" -Name "CDP_$($todayDate).txt" -ItemType File

    #Get AIA locations:
    certutil -getreg CA\CACertPublicationURLs > $AIAFile.FullName

    #Get CDP locations:
    certutil -getreg CA\CRLPublicationURLs > $CDPFile.FullName
}
else {
    New-Item -Name "Temp" -Path "C:\" -ItemType Directory
    $AIAFile = New-Item -Path "C:\Temp" -Name "AIA_$($todayDate).txt" -ItemType File
    $CDPFile = New-Item -Path "C:\Temp" -Name "CDP_$($todayDate).txt" -ItemType File

    #Get AIA locations:
    certutil -getreg CA\CACertPublicationURLs > $AIAFile.FullName

    #Get CDP locations:
    certutil -getreg CA\CRLPublicationURLs > $CDPFile.FullName
}