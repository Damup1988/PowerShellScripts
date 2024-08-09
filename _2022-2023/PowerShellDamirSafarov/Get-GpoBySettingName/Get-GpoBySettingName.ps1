$gpos = $(Get-GPO -all | Select-Object Id).Id
$settingName = ""

foreach ($gpo in $gpos) {
    [xml]$xml = Get-GPOReport -Guid $gpo -ReportType Xml

    $settings = @()
    $settings = $xml.gpo.Computer.ExtensionData.Extension.Policy.Name
    #$settings = $xml.gpo.User.ExtensionData.Extension.Policy.Name

    if ($settings -contains $settingName) {
        $(Get-GPO -Guid $gpo | Select-Object DisplayName).DisplayName
    }
}