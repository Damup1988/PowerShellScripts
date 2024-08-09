$urls = Get-Content -Path "C:\_bufer\_scripts\AzureAD\Add-RedirectURIBulk\urls.txt"

Connect-AzureAD

$appId = "ac313535-7402-4214-92d6-8d2b879f7c1a"
$app = Get-AzureADApplication -ObjectId $appId
$replyURLList = $app.ReplyUrls

foreach ($url in $urls) {
    $newURL = $url
    $replyURLList.Add($newURL)
    Set-AzureADApplication -ObjectId $appId -ReplyUrls $replyURLList
}