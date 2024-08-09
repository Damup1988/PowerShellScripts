Function Copy-File
{
  param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $SourceFileURL,
        [Parameter(Mandatory=$true)] [string] $TargetFileURL
    )
    Try {
        $Cred= Get-Credential
        $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
        #Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Ctx.Credentials = $Credentials
        #Get the source file
        $SourceFile =$Ctx.Web.GetFileByServerRelativeUrl($SourceFileURL)
        $Ctx.Load($SourceFile)
        $Ctx.ExecuteQuery()
        #Copy File to destination
        $SourceFile.CopyTo($TargetFileURL, $True)
        $Ctx.ExecuteQuery()
        Write-Host "File Copied from '$SourceFileURL' to '$TargetFileURL'" -F Green
       }
    Catch {
        write-host -f Red "Error Copying File!" $_.Exception.Message
    }
}

$count = @(1..10)

foreach ($c in $count) {
    Copy-File `
        -SiteURL "https://1r47lh.sharepoint.com" `
        -SourceFileURL "/Project Documents/MX003PRDABZGBR.etl" `
        -TargetFileURL "/Project Documents/MX003PRDABZGBR_$c.etl"
}