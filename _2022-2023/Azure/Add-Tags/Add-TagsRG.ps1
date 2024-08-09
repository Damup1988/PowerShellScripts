$tags = @{
    "AssignedTo" = "Srinivasa Degala"
    "ApplicationOwner" = "Srinivasa Degala"
    "ITVertical" = "Cots Engg"
    "Environment" = "Prod"
    "Change" = "CHG0048845"
    "CreatedBy" = "virp_damrov@petrofac.com"
}

$rgs = Get-Content -Path "C:\_bufer\_scripts\Azure\Add-Tags\list.txt"

New-AzTag `
    -ResourceId "/subscriptions/ebadd9b5-cc09-4131-8b8f-6f766c3c67a7/resourceGroups/RG-EUN-PRD-App-Compute" `
    -Tag $tags

foreach ($rg in $rgs) {
    New-AzTag `
        -ResourceId "/subscriptions/ebadd9b5-cc09-4131-8b8f-6f766c3c67a7/resourceGroups/$rg" `
        -Tag $tags
}