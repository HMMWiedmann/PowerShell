$ErrorActionPreference = "SilentlyContinue"
[int32]$errorcounter = 0
$minimumCertAgeDays = 60
 $timeoutMilliseconds = 32000
 $urls = @($args[0])
[int32]$counter = 0
#disabling the cert validation check. This is what makes this whole thing work with invalid certs...
 [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
foreach ($url in $urls)
 {
 Write-Host "starte SSL Check fuer $url ..."
 $req = [Net.HttpWebRequest]::Create($url)
 $req.Timeout = $timeoutMilliseconds
 $test = $req.GetResponse() 
 while($test -eq $null -and $counter -lt 5)
 {
    $test = $req.GetResponse() 
    sleep -Seconds 5
    $counter++
 }

    [string]$date = ($req.ServicePoint.Certificate.GetExpirationDateString()).split(" ")[0]
    $time = ($req.ServicePoint.Certificate.GetExpirationDateString()).split(" ")[1]
    $year = $date.split(".")[2]
    $month = $date.split(".")[1]
    $day = $date.split(".")[0]
    [string]$expirationSTR =  "$month/$day/$year $time"
    [datetime]$expiration = $expirationSTR


 [int]$certExpiresIn = ($expiration - $(get-date)).Days
$certName = $req.ServicePoint.Certificate.GetName()
 $certPublicKeyString = $req.ServicePoint.Certificate.GetPublicKeyString()
 $certSerialNumber = $req.ServicePoint.Certificate.GetSerialNumberString()
 $certThumbprint = $req.ServicePoint.Certificate.GetCertHashString()
 $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
 $certIssuer = $req.ServicePoint.Certificate.GetIssuerName()
 
if ($certExpiresIn -gt $minimumCertAgeDays)
 {
    Write-Host "Zertifikat fuer Seite $url laeuft in $certExpiresIn Tagen aus [$expiration]"
 }
 else
 {
    Write-Host "Zertifikat fuer Seite $url laeuft in $certExpiresIn Tagen aus [$expiration] grenzwert ist $minimumCertAgeDays Tage. Details:`n`nZertifikat Name: $certName`npublic key: $certPublicKeyString`nserial number: $certSerialNumber`nthumbprint: $certThumbprint`neffective date: $certEffectiveDate`nissuer: $certIssuer"
    $errorcounter++
 }
rv req
 rv expiration
 rv certExpiresIn
 }

 if($errorcounter -eq 0)
 {
    exit 0
 }
 else
 {
    exit 1001
 }