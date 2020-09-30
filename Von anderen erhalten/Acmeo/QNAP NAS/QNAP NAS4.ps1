$ErrorActionPreference= 'silentlycontinue'

[string]$ipadresse = $args[0]
[int]$errorcount = 0
[int]$goodcount = 0
$SNMP = new-object -ComObject olePrn.OleSNMP
$snmp.open($ipadresse,"public",5,3000)


[int]$nasTempStatus = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.6.0")).split(" ")[0]
if($nasTempStatus -le 60)
{
    Write-Host "Systemtemperatur = $nasTempStatus Grad"
    $goodcount++
}
elseif($nasFANStatus -ge 61)
{
    Write-Host "Systemtemperatur = $nasTempStatus Grad"
    $errorcount++
    $goodcount++
}
else
{
    Write-Host "Systemtemperatur = unbekannt"
}



[int]$nasHD1 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.1")).split(" ")[0] 
if($nasHD1 -ge 60)
{
    write-host "Die HDD1 hat $nasHD1 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD1 -or $nasHD1 -eq "")
{
    write-host "Die HDD1 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD1 hat $nasHD1 Grad Temperatur"
    $goodcount++
}
[int]$nasHD2 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.2")).split(" ")[0]
if($nasHD2 -ge 60)
{
    write-host "Die HDD2 hat $nasHD2 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD2 -or $nasHD2 -eq "")
{
    write-host "Die HDD2 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD2 hat $nasHD2 Grad Temperatur"
    $goodcount++
}
[int]$nasHD3 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.3")).split(" ")[0]
if($nasHD3 -ge 60)
{
    write-host "Die HDD3 hat $nasHD3 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD3 -or $nasHD3 -eq "")
{
    write-host "Die HDD3 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD3 hat $nasHD3 Grad Temperatur"
    $goodcount++
}
[int]$nasHD4 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.4")).split(" ")[0]
if($nasHD4 -ge 60)
{
    write-host "Die HDD4 hat $nasHD4 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD4 -or $nasHD4 -eq "")
{
    write-host "Die HDD4 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD4 hat $nasHD4 Grad Temperatur"
    $goodcount++
}

[int]$nasHD5 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.5")).split(" ")[0]
if($nasHD5 -ge 60)
{
    write-host "Die HDD5 hat $nasHD5 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD5 -or $nasHD5 -eq "")
{
    write-host "Die HDD5 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD5 hat $nasHD5 Grad Temperatur"
    $goodcount++
}

[int]$nasHD6 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.6")).split(" ")[0]
if($nasHD6 -ge 60)
{
    write-host "Die HDD6 hat $nasHD6 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD6 -or $nasHD6 -eq "")
{
    write-host "Die HDD6 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD6 hat $nasHD6 Grad Temperatur"
    $goodcount++
}

[int]$nasHD7 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.7")).split(" ")[0]
if($nasHD7 -ge 60)
{
    write-host "Die HDD7 hat $nasHD7 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD7 -or $nasHD7 -eq "")
{
    write-host "Die HDD7 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD7 hat $nasHD7 Grad Temperatur"
    $goodcount++
}

[int]$nasHD8 = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.3.8")).split(" ")[0]
if($nasHD8 -ge 60)
{
    write-host "Die HDD8 hat $nasHD8 Grad Temperatur"
    $errorcount++
    $goodcount++
}
elseif($null -eq $nasHD8 -or $nasHD8 -eq "")
{
    write-host "Die HDD8 keine Temperatur gefunden."
}
else
{
    write-host "Die HDD8 hat $nasHD8 Grad Temperatur"
    $goodcount++
}


#######################################



[string]$nasHDDStatus1 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.1")
if($nasHDDStatus1 -eq "GOOD")
{
    write-host "HDD1 Status= OK"
    $goodcount++
}
elseif($null -eq $nasHDDStatus1 -or $nasHDDStatus1 -eq "" -or $nasHDDStatus1 -eq "--")
{
    write-host "HDD1 Status= NA"
}
else
{
    write-host "HDD1 Status= $nasHDDStatus1"
     $errorcount++
     $goodcount++     
}
[string]$nasHDDStatus2 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.2")
if($nasHDDStatus2 -eq "GOOD")
{
    write-host "HDD2 Status= OK"
    $goodcount++
}
elseif($null -eq $nasHDDStatus2 -or $nasHDDStatus2 -eq "" -or $nasHDDStatus2 -eq "--")
{
    write-host "HDD2 Status= NA"
}
else
{
    write-host "HDD2 Status= $nasHDDStatus2"
     $errorcount++
     $goodcount++     
}
[string]$nasHDDStatus3 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.3")
if($nasHDDStatus3 -eq "GOOD")
{
    write-host "HDD3 Status= OK"
    $goodcount++
}
elseif($null -eq $nasHDDStatus3 -or $nasHDDStatus3 -eq ""  -or $nasHDDStatus3 -eq "--")
{
    write-host "HDD3 Status= NA"
}
else
{
    write-host "HDD3 Status= $nasHDDStatus3"
     $errorcount++ 
     $goodcount++    
}
[string]$nasHDDStatus4 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.4")
if($nasHDDStatus4 -eq "GOOD")
{
    write-host "HDD4 Status= OK"
    $goodcount++
}
elseif($null -eq $nasHDDStatus4 -or $nasHDDStatus4 -eq ""  -or $nasHDDStatus4 -eq "--")
{
    write-host "HDD4 Status= NA"
}
else
{
    write-host "HDD4 Status= $nasHDDStatus4"
     $errorcount++
     $goodcount++     
}

[string]$nasHDDStatus5 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.5")
if($nasHDDStatus5 -eq "GOOD")
{
    write-host "HDD5 Status= OK"
    $goodcount++ 
}
elseif($null -eq $nasHDDStatus5 -or $nasHDDStatus5 -eq "" -or $nasHDDStatus5 -eq "--")
{
    write-host "HDD5 Status= NA"
}
else
{
    write-host "HDD5 Status= $nasHDDStatus5"
     $errorcount++ 
     $goodcount++     
}

[string]$nasHDDStatus6 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.6")
if($nasHDDStatus6 -eq "GOOD")
{
    write-host "HDD6 Status= OK"
    $goodcount++ 
}
elseif($null -eq $nasHDDStatus6 -or $nasHDDStatus6 -eq "" -or $nasHDDStatus6 -eq "--")
{
    write-host "HDD6 Status= NA"
}
else
{
    write-host "HDD6 Status= $nasHDDStatus6"
     $errorcount++
     $goodcount++      
}

[string]$nasHDDStatus7 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.7")
if($nasHDDStatus7 -eq "GOOD")
{
    write-host "HDD7 Status= OK"
    $goodcount++ 
}
elseif($null -eq $nasHDDStatus7 -or $nasHDDStatus7 -eq "" -or $nasHDDStatus7 -eq "--")
{
    write-host "HDD7 Status= NA"
}
else
{
    write-host "HDD7 Status= $nasHDDStatus7"
     $errorcount++ 
     $goodcount++     
}

[string]$nasHDDStatus8 = $snmp.Get(".1.3.6.1.4.1.24681.1.2.11.1.7.8")
if($nasHDDStatus8 -eq "GOOD")
{
    write-host "HDD8 Status= OK"
    $goodcount++ 
}
elseif($null -eq $nasHDDStatus8 -or $nasHDDStatus8 -eq "" -or $nasHDDStatus8 -eq "--")
{
    write-host "HDD8 Status= NA"
}
else
{
    write-host "HDD8 Status= $nasHDDStatus8"
     $errorcount++ 
     $goodcount++     
}
if($goodcount -eq 0)
{
    Write-Host "Es konnten keine Daten erfasst werden."
    Write-Host "Pruefen Sie die SNMP Schnittstelle an der QNAP"
    exit 1001
}

if($errorcount -ge 1)
{
    exit 1001
}
else
{
    exit 0   
}

