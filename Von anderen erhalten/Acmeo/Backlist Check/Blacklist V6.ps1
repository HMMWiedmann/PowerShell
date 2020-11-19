<#
    Blacklist Check SKript 
    von Marcus von der Werth

    Als Befehlszeile bitte IP oder Domain angeben
#>
$Job = Start-Job -ScriptBlock {
$IP = $args[0] 
$reversedIP = ($IP -split '\.')[3..0] -join '.'
$blacklistServers = @(
    'b.barracudacentral.org'
    'spam.rbl.msrbl.net'
    'zen.spamhaus.org'
    'bl.deadbeef.com'
    'bl.emailbasura.org'
    'bl.spamcannibal.org'
    'bl.spamcop.net'
    'blackholes.five-ten-sg.com'
    'blacklist.woody.ch'
    'bogons.cymru.com'
    'cbl.abuseat.org'
    'cdl.anti-spam.org.cn'
    'combined.abuse.ch'
    'combined.rbl.msrbl.net'
    'db.wpbl.info'
    'dnsbl-1.uceprotect.net'
    'dnsbl-2.uceprotect.net'
    'dnsbl-3.uceprotect.net'
    'dnsbl.ahbl.org'
    'dnsbl.cyberlogic.net'
    'dnsbl.inps.de'
    'dnsbl.sorbs.net'
    'drone.abuse.ch'
    'duinv.aupads.org'
    'dul.dnsbl.sorbs.net'
    'dul.ru'
    'dyna.spamrats.com'
    'dynip.rothen.com'
    'http.dnsbl.sorbs.net'
    'images.rbl.msrbl.net'
    'ips.backscatterer.org'
    'ix.dnsbl.manitu.net'
    'korea.services.net'
    'misc.dnsbl.sorbs.net'
    'noptr.spamrats.com'
    'ohps.dnsbl.net.au'
    'omrs.dnsbl.net.au'
    'orvedb.aupads.org'
    'osps.dnsbl.net.au'
    'osrs.dnsbl.net.au'
    'owfs.dnsbl.net.au'
    'owps.dnsbl.net.au'
    'pbl.spamhaus.org'
    'phishing.rbl.msrbl.net'
    'probes.dnsbl.net.au'
    'proxy.bl.gweep.ca'
    'proxy.block.transip.nl'
    'psbl.surriel.com'
    'rbl.interserver.net'
    'rdts.dnsbl.net.au'
    'relays.bl.gweep.ca'
    'relays.bl.kundenserver.de'
    'relays.nether.net'
    'residential.block.transip.nl'
    'ricn.dnsbl.net.au'
    'rmst.dnsbl.net.au'
    'sbl.spamhaus.org'
    'short.rbl.jp'
    'smtp.dnsbl.sorbs.net'
    'socks.dnsbl.sorbs.net'
    'spam.abuse.ch'
    'spam.dnsbl.sorbs.net'
    'spam.spamrats.com'
    'spamlist.or.kr'
    'spamrbl.imp.ch'
    't3direct.dnsbl.net.au'
    'tor.ahbl.org'
    'tor.dnsbl.sectoor.de'
    'torserver.tor.dnsbl.sectoor.de'
    'ubl.lashback.com'
    'ubl.unsubscore.com'
    'virbl.bit.nl'
    'virus.rbl.jp'
    'virus.rbl.msrbl.net'
    'web.dnsbl.sorbs.net'
    'wormrbl.imp.ch'
    'xbl.spamhaus.org'
    'zombie.dnsbl.sorbs.net'
)

$blacklistedOn = @()

foreach ($server in $blacklistServers)
{
    
    $fqdn = "$reversedIP.$server"
    Write-Host "Teste Server $server"
    }
 

    try
    {
        $null = [System.Net.Dns]::GetHostEntry($fqdn)
        $blacklistedOn += $server
        Write-Host ""
        Write-Host "___________________________________________________"
        Write-Host "$IP ist blacklistet auf diesen Server $server"
    }
    catch { }



}
$Job | Wait-Job -Timeout 120 | Out-Null
$Job | Stop-Job 
Receive-Job $Job 
Remove-Job -force $Job
if ($blacklistedOn.Count -gt 0)
{
    Write-Host ""
    Write-Host "___________________________________________________"
    Write-Host "$IP ist blacklistet auf diesen Servern: $($blacklistedOn -join ', ')"
    Exit 1010
}
else
{
    Write-Host "$IP is not currently blacklisted on any server."

    Exit 0
}