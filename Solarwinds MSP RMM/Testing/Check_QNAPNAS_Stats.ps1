$ErrorActionPreference= 'silentlycontinue'

# [string]$ipadresse = $args[0]
[int]$errorcount = 0
[int]$goodcount = 0
$SNMP = new-object -ComObject olePrn.OleSNMP
$snmp.open($ipadresse,"public",5,3000)

#region NAS Stats

#region model name
[int]$nasModelName = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.12.0")).split(" ")[0]
if($nasModelName)
{
    Write-Host "Modelname = $nasModelName"
    $goodcount++
}
elseif($nasModelName)
{
    Write-Host "Modelname = $nasModelName"
    $errorcount++
    $goodcount++
}
else
{
    Write-Host "Modelname = unbekannt"
}
#endregion 

#region sys temp
[int]$nasTempStatus = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.6.0")).split(" ")[0]
if($nasTempStatus -le 60)
{
    Write-Host "Systemtemperatur = $nasTempStatus Grad"
    $goodcount++
}
elseif($nasTempStatus -ge 61)
{
    Write-Host "Systemtemperatur = $nasTempStatus Grad"
    $errorcount++
    $goodcount++
}
else
{
    Write-Host "Systemtemperatur = unbekannt"
}
#endregion

#region cpu temp
[int]$nasCPUTemp = ($snmp.Get(".1.3.6.1.4.1.24681.1.2.5.0")).split(" ")[0]
if($nasCPUTemp -le 50)
{
    Write-Host "CPU-temperatur = $nasCPUTemp Grad"
    $goodcount++
}
elseif($nasCPUTemp -ge 51)
{
    Write-Host "CPU-temperatur = $nasCPUTemp Grad"
    $errorcount++
    $goodcount++
}
else
{
    Write-Host "CPU-temperatur = unbekannt"
}
#endregion
#endregion

#region HDD Temps

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

#endregion

#region HDD Smart Status

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

#endregion

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

