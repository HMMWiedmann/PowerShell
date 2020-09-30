<#
    getestet auf TS-251
#>

#region Hilfsfunktion
function Get-SNMPDataInformation
{
    param (
        # SNMP-Object
        [Parameter(Mandatory = $true)]
        [System.__ComObject]
        $SNMPObj,
        
        # SNMP-PropertyName
        [Parameter(Mandatory = $true)]
        [string]
        $PropertyName,

        # SNMP-OID
        [Parameter(Mandatory = $true)]
        [string]
        $OID       
    )
    
    try {
        $snmpdata = $SNMPObj.Get($OID)
    }
    catch {
        Write-Host "$PSItem.Exception.Message"
    }

    if($snmpdata)
    {
        Write-Host "$($PropertyName) : $($snmpdata)"
        $global:AllSNMPData.Add("$PropertyName", "$snmpdata")
        $global:goodcount++
    }
    else
    {
        Write-Host "$($PropertyName) : unbekannt"
        $global:errorcount++
    }
}
#endregion

$ipadresse = "10.18.0.9"
# $ErrorActionPreference= 'silentlycontinue'

# [string]$ipadresse = $args[0]
[int]$errorcount = 0
[int]$goodcount = 0
$AllSNMPData = @{}
$SNMP = New-Object -ComObject olePrn.OleSNMP
$SNMP.open($ipadresse,"public",5,3000)

Write-Host "-----------------------------------------------------------------------"

#region Sys Stats

# 1.3.6.1.4.1.24681.1.2.1.0: NAS-MIB|system info|system cpu -usage
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "NAS_CPU_Usage" -OID ".1.3.6.1.4.1.24681.1.2.1.0"
# 1.3.6.1.4.1.24681.1.2.2.0: NAS-MIB|system info|system total mem
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "NAS_MEM_Total" -OID ".1.3.6.1.4.1.24681.1.2.2.0"
# 1.3.6.1.4.1.24681.1.2.3.0: NAS-MIB|system info|system free mem
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "NAS_MEM_free" -OID ".1.3.6.1.4.1.24681.1.2.3.0"
# 1.3.6.1.4.1.24681.1.2.5.0: NAS-MIB|system info|cpu-temperature
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "NAS_CPU_Temp" -OID ".1.3.6.1.4.1.24681.1.2.5.0"
# 1.3.6.1.4.1.24681.1.2.6.0: NAS-MIB|system info|system temperature
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "NAS_Sys_Temp" -OID ".1.3.6.1.4.1.24681.1.2.6.0"

#endregion

Write-Host "-----------------------------------------------------------------------"

if($goodcount -eq 0)
{
    Write-Host "Es konnten keine Daten erfasst werden."
    Write-Host "Pruefen Sie die SNMP Schnittstelle an der QNAP"
    #exit 1001
}

if($errorcount -ge 1)
{
    #exit 1001
}
else
{
    #exit 0   
}