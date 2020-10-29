#$ErrorActionPreference = "SilentlyContinue"
[int32]$errorcounter = 0
# $minimumCertAgeDays = 14
$timeoutMilliseconds = 32000
# $urls = "https://mail.hm-netzwerke.de"
[int32]$counter = 0
#disabling the cert validation check. This is what makes this whole thing work with invalid certs...
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
foreach ($url in $urls)
{
    Write-Verbose "starte SSL Check fuer $url ..."
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Timeout = $timeoutMilliseconds
    $test = $req.GetResponse() 
    while($null -eq $test -and $counter -lt 5)
    {
        $test = $req.GetResponse() 
        Start-Sleep -Seconds 5
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
        Write-Host "$certExpiresIn Tage verbleibend fuer das Zertifikat von $url`nthumbprint: $certThumbprint"
    }
    else
    {
        Write-Host "$certExpiresIn Tage verbleibend fuer das Zertifikat von $url. Details:`n`nZertifikat Name: $certName`npublic key: $certPublicKeyString`nserial number: $certSerialNumber`nthumbprint: $certThumbprint`neffective date: $certEffectiveDate`nissuer: $certIssuer"
        $errorcounter++
    }
    Remove-Variable req
    Remove-Variable expiration
    Remove-Variable certExpiresIn
}