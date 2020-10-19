$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

$body = "{`n	`"username`": `"`",`n	`"password`": `"`"`n}`n"

$response = Invoke-RestMethod 'https://api.unifilabs.com/login' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json