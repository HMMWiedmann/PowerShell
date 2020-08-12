$Computernames = (Get-ADComputer -Filter { DNSHostname -like "*Hyperv*" }).Name
$Item = "C:\Tools\ADS1809"
 
foreach($comp in $Computernames)
{
    Copy-Item -Path $Item -Recurse -Destination \\$Comp\c$\Tools\ADK1803
} 