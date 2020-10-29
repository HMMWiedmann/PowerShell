"https://www.frankysweb.de/exchange-2019-die-basiskonfiguration/"

$EXDBName = "HMLABEXDB01"

Get-MailboxDatabase -Server $env:COMPUTERNAME | Set-MailboxDatabase -Name $EXDBName
Move-DatabasePath $EXDBName -EdbFilePath "c:\$EXDBName\$EXDBName.edb" -LogFolderPath "c:\$EXDBName"

"Hinweis: Alle angegebenen Namen müssen auch für das Zertifikat konfiguriert werden.

Das folgende Script kann nach dem Ändern der ersten 4 Zeilen in der Exchange Management Shell ausgeführt werden:"

$servername = $env:COMPUTERNAME
$internalhostname = "mail.hm-lab.de"
$externalhostname = "mail.hm-lab.de"
$autodiscoverhostname = "autodiscover.hm-lab.de"

$owainturl = "https://" + "$internalhostname" + "/owa"
$owaexturl = "https://" + "$externalhostname" + "/owa"
$ecpinturl = "https://" + "$internalhostname" + "/ecp"
$ecpexturl = "https://" + "$externalhostname" + "/ecp"
$ewsinturl = "https://" + "$internalhostname" + "/EWS/Exchange.asmx"
$ewsexturl = "https://" + "$externalhostname" + "/EWS/Exchange.asmx"
$easinturl = "https://" + "$internalhostname" + "/Microsoft-Server-ActiveSync"
$easexturl = "https://" + "$externalhostname" + "/Microsoft-Server-ActiveSync"
$oabinturl = "https://" + "$internalhostname" + "/OAB"
$oabexturl = "https://" + "$externalhostname" + "/OAB"
$mapiinturl = "https://" + "$internalhostname" + "/mapi"
$mapiexturl = "https://" + "$externalhostname" + "/mapi"
$aduri = "https://" + "$autodiscoverhostname" + "/Autodiscover/Autodiscover.xml"
Get-OwaVirtualDirectory -Server $servername | Set-OwaVirtualDirectory -internalurl $owainturl -externalurl $owaexturl -Confirm:$false
Get-EcpVirtualDirectory -server $servername | Set-EcpVirtualDirectory -internalurl $ecpinturl -externalurl $ecpexturl -Confirm:$false
Get-WebServicesVirtualDirectory -server $servername | Set-WebServicesVirtualDirectory -internalurl $ewsinturl -externalurl $ewsexturl -Confirm:$false
Get-ActiveSyncVirtualDirectory -Server $servername | Set-ActiveSyncVirtualDirectory -internalurl $easinturl -externalurl $easexturl -Confirm:$false
Get-OabVirtualDirectory -Server $servername | Set-OabVirtualDirectory -internalurl $oabinturl -externalurl $oabexturl -Confirm:$false
Get-MapiVirtualDirectory -Server $servername | Set-MapiVirtualDirectory -externalurl $mapiexturl -internalurl $mapiinturl -Confirm:$false
Get-OutlookAnywhere -Server $servername | Set-OutlookAnywhere -externalhostname $externalhostname -internalhostname $internalhostname -ExternalClientsRequireSsl:$true -InternalClientsRequireSsl:$true -ExternalClientAuthenticationMethod 'Negotiate'  -Confirm:$false
Get-ClientAccessService $servername | Set-ClientAccessService -AutoDiscoverServiceInternalUri $aduri -Confirm:$false
Get-OwaVirtualDirectory -Server $servername | Format-List server,externalurl,internalurl
Get-EcpVirtualDirectory -server $servername | Format-List server,externalurl,internalurl
Get-WebServicesVirtualDirectory -server $servername | Format-List server,externalurl,internalurl
Get-ActiveSyncVirtualDirectory -Server $servername | Format-List server,externalurl,internalurl
Get-OabVirtualDirectory -Server $servername | Format-List server,externalurl,internalurl
Get-MapiVirtualDirectory -Server $servername | Format-List server,externalurl,internalurl
Get-OutlookAnywhere -Server $servername | Format-List servername,ExternalHostname,InternalHostname
Get-ClientAccessService $servername | Format-List name,AutoDiscoverServiceInternalUri