$ErrorActionPreference= 'silentlycontinue'

[string]$ipadresse = $args[0]
[int]$errorcount = 0
$SNMP = new-object -ComObject olePrn.OleSNMP
$snmp.open($ipadresse,"public",5,3000)


[int]$nasFANStatus = $snmp.Get(".1.3.6.1.4.1.6574.1.4.2.0")
if($nasFANStatus -eq 1)
{
    Write-Host "Fanstatus = OK"
}
elseif($nasFANStatus -eq 2)
{
    Write-Host "Fanstatus = FEHLER"
    $errorcount++
}
else
{
    Write-Host "Fanstatus = unbekannt"
}



[int]$nasHD1 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.0") 
if($nasHD1 -ge 60)
{
    write-host "Die HDD1 hat $nasHD1 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD1 hat $nasHD1 Grad Temperatur"
}
[int]$nasHD2 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.1")
if($nasHD2 -ge 60)
{
    write-host "Die HDD2 hat $nasHD2 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD2 hat $nasHD2 Grad Temperatur"
}
[int]$nasHD3 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.2")
if($nasHD3 -ge 60)
{
    write-host "Die HDD3 hat $nasHD3 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD3 hat $nasHD3 Grad Temperatur"
}
[int]$nasHD4 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.3")
if($nasHD4 -ge 60)
{
    write-host "Die HDD4 hat $nasHD4 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD4 hat $nasHD4 Grad Temperatur"
}

[int]$nasHD5 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.4")
if($nasHD5 -ge 60)
{
    write-host "Die HDD5 hat $nasHD5 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD5 hat $nasHD5 Grad Temperatur"
}

[int]$nasHD6 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.5")
if($nasHD6 -ge 60)
{
    write-host "Die HDD6 hat $nasHD6 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD6 hat $nasHD6 Grad Temperatur"
}

[int]$nasHD7 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.6")
if($nasHD7 -ge 60)
{
    write-host "Die HDD7 hat $nasHD7 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD7 hat $nasHD7 Grad Temperatur"
}

[int]$nasHD8 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.6.7")
if($nasHD8 -ge 60)
{
    write-host "Die HDD8 hat $nasHD8 Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die HDD8 hat $nasHD8 Grad Temperatur"
}


#######################################



[int]$nasSysTemp = $snmp.Get(".1.3.6.1.4.1.6574.1.2.0")
if($nasSysTemp -ge 50)
{
    write-host "Die System hat $nasSysTemp Grad Temperatur"
    $errorcount++
}
else
{
    write-host "Die System hat $nasSysTemp Grad Temperatur"
}





[int]$nasHDDStatus1 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.0")
if($nasHDDStatus1 -eq 1)
{
    write-host "HDD1 Status= OK"
}
elseif($null -eq $nasHDDStatus1  -or $nasHDDStatus1 -eq 0)
{
     write-host "HDD1 Status= unbekannt"
}
else
{
    write-host "HDD1 Status= $nasHDDStatus1"
     $errorcount++     
}
[int]$nasHDDStatus2 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.1")
if($nasHDDStatus2 -eq 1)
{
    write-host "HDD2 Status= OK"
}
elseif($null -eq $nasHDDStatus2 -or $nasHDDStatus2 -eq 0)
{
     write-host "HDD2 Status= unbekannt"
}
else
{
    write-host "HDD2 Status= $nasHDDStatus2"
     $errorcount++     
}
[int]$nasHDDStatus3 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.2")
if($nasHDDStatus3 -eq 1)
{
    write-host "HDD3 Status= OK"
}
elseif($null -eq $nasHDDStatus3  -or $nasHDDStatus3 -eq 0)
{
     write-host "HDD3 Status= unbekannt"
}
else
{
    write-host "HDD3 Status= $nasHDDStatus3"
     $errorcount++     
}
[int]$nasHDDStatus4 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.3")
if($nasHDDStatus4 -eq 1)
{
    write-host "HDD4 Status= OK"
}
elseif($null -eq $nasHDDStatus4  -or $nasHDDStatus4 -eq 0)
{
     write-host "HDD4 Status= unbekannt"
}
else
{
    write-host "HDD4 Status= $nasHDDStatus4"
     $errorcount++     
}

[int]$nasHDDStatus5 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.4")
if($nasHDDStatus5 -eq 1)
{
    write-host "HDD5 Status= OK"
}
elseif($null -eq $nasHDDStatus5 -or $nasHDDStatus5 -eq 0)
{
     write-host "HDD5 Status= unbekannt"
}
else
{
    write-host "HDD5 Status= $nasHDDStatus5"
     $errorcount++     
}

[int]$nasHDDStatus6 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.5")
if($nasHDDStatus6 -eq 1)
{
    write-host "HDD6 Status= OK"
}
elseif($null -eq $nasHDDStatus6 -or $nasHDDStatus6 -eq 0)
{
     write-host "HDD6 Status= unbekannt"
}
else
{
    write-host "HDD6 Status= $nasHDDStatus6"
     $errorcount++     
}

[int]$nasHDDStatus7 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.6")
if($nasHDDStatus7 -eq 1)
{
    write-host "HDD7 Status= OK"
}
elseif($null -eq $nasHDDStatus7 -or $nasHDDStatus7 -eq 0)
{
     write-host "HDD7 Status= unbekannt"
}
else
{
    write-host "HDD7 Status= $nasHDDStatus7"
     $errorcount++     
}

[int]$nasHDDStatus8 = $snmp.Get(".1.3.6.1.4.1.6574.2.1.1.5.7")
if($nasHDDStatus8 -eq 1)
{
    write-host "HDD8 Status= OK"
}
elseif($null -eq $nasHDDStatus8 -or $nasHDDStatus8 -eq 0)
{
     write-host "HDD8 Status= unbekannt"
}
else
{
    write-host "HDD8 Status= $nasHDDStatus8"
     $errorcount++     
}


if($errorcount -ge 1)
{
    exit 1001
}
else
{
    exit 0   
}

