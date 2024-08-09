# Set up authentication
$clientId = "tenant_id"
$tenantId = "tenant_id"
$clientSecret = "client_secret"
$authority = "https://login.microsoftonline.com/$tenantId/oauth2/token"

$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = "https://graph.microsoft.com"
}

$token = Invoke-RestMethod -Uri $authority -Method Post -Body $body

# Make the Graph request
$headers = @{
    "Authorization" = "Bearer $($token.access_token)"
}

#$requestUri = "https://graph.microsoft.com/v1.0/groups/6debdd45-fe9d-406d-bd94-6a9a52bf8f57/members"
$requestUri = "https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityCounts(period='D7')?\`$filter=reportType%20eq%20'TeamsUserActivityCounts'&\`$top=1"

$response = Invoke-RestMethod -Uri $requestUri -Headers $headers

# Print the response
$response
