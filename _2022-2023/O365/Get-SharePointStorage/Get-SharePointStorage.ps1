$clientId = "18edaf0d-409e-455f-a478-5249cd694a30"
$tenantId = "9b9f9a6f-c781-43ac-a95e-d25f14d1eeb2"
$clientSecret = "zFZ8Q~6Twedj8sCHAy~I9~PebeAyrWP~pMto6ac3"
$authority = "https://login.microsoftonline.com/$tenantId/oauth2/token"

# Function to acquire a token for the Graph API
function Get-GraphToken {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        resource      = "https://graph.microsoft.com"
    }
    
    $token = Invoke-RestMethod -Uri $authority -Method Post -Body $body
    return $token.access_token
}

# Function to get used space for a SharePoint site
<#function Get-SiteUsedSpace {
    param (
        [string]$siteId
    )

    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    $siteDriveInfo = Invoke-RestMethod `
        -Headers $headers `
        -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drive" `
        -Method Get
    return $siteDriveInfo.quota.used
}#>

$accessToken = Get-GraphToken
$headers = @{
    Authorization = "Bearer $accessToken"
}

# get all sites
<#$allSites = $(Invoke-RestMethod `
    -Headers $headers `
    -Uri "https://graph.microsoft.com/v1.0/sites?search=*" `
    -Method Get).Value.id#>

Invoke-RestMethod `
    -Headers $headers `
    -Uri "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageStorage(period='D7')" `
    -Method Get

$IDs = @()
foreach ($site in $allSites) {
    $IDs += $site.Split(',')[1]
}

$totalSpaceUsed = 0
foreach ($id in $IDs) {
    $totalSpaceUsed += Get-SiteUsedSpace -siteId $id
}

$totalSpaceUsedMbites = $totalSpaceUsed / 1024 / 1024
$totalSpaceUsedMbites