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
        Write-Host "Es gab einen Fehler beim Auslesen"
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

# $ipadresse = "10.18.0.9"
$ErrorActionPreference= 'silentlycontinue'
[string]$ipadresse = $args[0]
[int]$errorcount = 0
[int]$goodcount = 0
$AllSNMPData = @{}
$SNMP = New-Object -ComObject olePrn.OleSNMP
$SNMP.open($ipadresse,"public",5,3000)

Write-Host "-----------------------------------------------------------------------"

#region Diskinformation 1

# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.1: NAS-MIB|disk: 1|disk smart info
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_1_smart_info" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.1"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.1: NAS-MIB|disk: 1|disk temperture
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_1_temperature" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.1"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.1: NAS-MIB|disk: 1|disk model
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_1_model" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.1"

#endregion

Write-Host "-----------------------------------------------------------------------"

#region Diskinformation 2

# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.2: NAS-MIB|disk: 2|disk smart info
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_2_smart_info" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.2"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.2: NAS-MIB|disk: 2|disk temperture
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_2_temperature" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.2"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.2: NAS-MIB|disk: 2|disk model
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_2_model" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.2"

#endregion

Write-Host "-----------------------------------------------------------------------"

#region Diskinformation 3

# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.3: NAS-MIB|disk: 3|disk smart info
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_3_smart_info" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.3"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.3: NAS-MIB|disk: 3|disk temperture
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_3_temperature" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.3"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.3: NAS-MIB|disk: 3|disk model
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_3_model" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.3"

#endregion

Write-Host "-----------------------------------------------------------------------"

#region Diskinformation 4

# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.4: NAS-MIB|disk: 4|disk smart info
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_4_smart_info" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.4.4"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.4: NAS-MIB|disk: 4|disk temperture
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_4_temperature" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6.4"
# 1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.4: NAS-MIB|disk: 4|disk model
Get-SNMPDataInformation -SNMPObj $SNMp -PropertyName "Disk_4_model" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.8.4"

#endregion

Write-Host "-----------------------------------------------------------------------"

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