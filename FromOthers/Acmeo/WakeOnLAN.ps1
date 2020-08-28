# acmeo Script für Wake on Lan
# Von Marcus von der Werth
# 
# Bitte geben Sie zwischen den "" Ihre API Key aus dem Dashboard ein
# Den API Key erhalten Sie aus dem Dashboard unter Einstellungen --> allgemeine Einstellungen --> API
# Nach dem ersten Durchlauf des Scripts zeigt es Ihre benötigten SideID´s an Ihrer Kunden und Standorte.
# Die gewünschte SideID geben Sie dann als Befehlszeile im Dashboard mit an
#####################################

[string]$APIkey = " "

# Beispiel:
# [string]$APIkey = "42254cc6e78d7fcdaa746dd029ee2d3d"


# AB HIER BITTE NICHTS MEHR ÄNDERN

#####################################

if ($APIkey -eq " ")
{
    Write-Host "Es fehlt Ihr API Schluessel im Script."
    Write-Host "Bitte Script mit Editor oeffnen und Anweisung folgen"
    exit 1001
}

[int]$sideid = $args[0]
[string]$APIurl = "https://wwwgermany1.systemmonitor.eu.com/api/?apikey=$APIkey"

if ($sideid -eq "-logfile" -or $sideid -eq "" -or $null -eq $sideid -or $sideid -eq "-logfile ..\task_*.log")
{
    $ClientsURL = "$APIurl&service=list_clients"
    Write-Host "|||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    [xml]$XMLclients = (new-object System.Net.WebClient).DownloadString($ClientsURL)

    foreach ($XMLclientsList in $XMLclients.result.items.client) 
    {
        $ClientID = $XMLclientsList.clientid
        $ClientName = $XMLclientsList.name."#cdata-section"
        $SiteURL = "$APIurl&service=list_sites&clientid=$ClientID"
        [xml]$XMLSite = (new-object System.Net.WebClient).DownloadString($SiteURL)
        Write-Host "____________________________________"
        Write-Host "Kunde: $ClientName"
        Write-Host ""
        foreach ($XMLSiteList in $XMLSite.result.items.site) {
            $SiteID2 = $XMLSiteList.siteid
            $SiteName = $XMLSiteList.name."#cdata-section"        
            Write-Host "Standort: $SiteName | SiteID: $SiteID2"       
        }
    }
}
else
{
    $url = "$($apiurl)&service=list_workstations&siteid=$sideid"
    [xml]$xmlmac = (new-object System.Net.WebClient).DownloadString($url)
    $debug = $xmlmac.result | Out-String
    Write-Host "Gewaehlte SideID ist $sideid"
    Write-Host "____________________________"
    Write-Host ""
    [int]$count = 0

    foreach ($xmlmacws in $xmlmac.result.items.workstation) 
    {
        [string]$macString = $xmlmacws.mac1."#cdata-section"

        if($macString.Length -eq 17)
        {        
            $mac = $macString.split(':') | ForEach-Object{ [byte]('0x' + $_) }
            $UDPclient = new-Object System.Net.Sockets.UdpClient
            $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
            $packet = [byte[]](,0xFF * 6)
            $packet += $mac * 16
            [void] $UDPclient.Send($packet, $packet.Length)
            write-output "MAC A mit Magic Packet $($packet.Length) Zeichen gesendet. MAC: $macString"
        }

        $macString = $xmlmacws.mac2."#cdata-section"

        if($macString.Length -eq 17)
        {        
            $mac = $macString.split(':') | ForEach-Object{ [byte]('0x' + $_) }
            $UDPclient = new-Object System.Net.Sockets.UdpClient
            $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
            $packet = [byte[]](,0xFF * 6)
            $packet += $mac * 16
            [void] $UDPclient.Send($packet, $packet.Length)
            write-output "MAC B mit Magic Packet $($packet.Length) Zeichen gesendet. MAC: $macString"
        }

        $macString = $xmlmacws.mac3."#cdata-section"

        if($macString.Length -eq 17)
        {        
            $mac = $macString.split(':') | ForEach-Object{ [byte]('0x' + $_) }
            $UDPclient = new-Object System.Net.Sockets.UdpClient
            $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
            $packet = [byte[]](,0xFF * 6)
            $packet += $mac * 16
            [void] $UDPclient.Send($packet, $packet.Length)
            write-output "MAC C mit Magic Packet $($packet.Length) Zeichen gesendet. MAC: $macString"
        }

        $count++

        if($count -eq 10)
        {
            # Damit nicht alle Rechner gleichzeitig starten wird hier in der Gruppe alle 10 Rechner eine Wartezeit von 3 Sekunden eingeführt
            $count = 0
            Start-Sleep -Seconds 3
        }
    }
}
