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
    }
}

#endregion
[int]$errorcount = 0
[int]$goodcount = 0
$AllSNMPData = @{}
$SNMP = New-Object -ComObject olePrn.OleSNMP
$SNMP.open($ipadresse,"public",5,3000)

#region Volume 1
# 1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.8.1: NAS-MIB|volume: 1|volume name
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_1_Name" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.8.1"
# 1.3.6.1.4.1.24681.1.2.17.1.4.1: NAS-MIB|system volume: 1|sys volume total size
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_1_total_size" -OID ".1.3.6.1.4.1.24681.1.2.17.1.4.1"
# 1.3.6.1.4.1.24681.1.2.17.1.5.1: NAS-MIB|system volume: 1|sys volume free size
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_1_free_size" -OID ".1.3.6.1.4.1.24681.1.2.17.1.5.1"
# 1.3.6.1.4.1.24681.1.2.17.1.6.1: NAS-MIB|system volume: 1|sys volume status
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_1_status" -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.1"
#endregion

Write-Host "-----------------------------------------------------------------------"

#region Volume 2
# 1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.8.2: NAS-MIB|volume: 2|volume name
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_2_Name" -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.8.2"
# 1.3.6.1.4.1.24681.1.2.17.1.4.2: NAS-MIB|system volume: 2|sys volume total size
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_2_total_size" -OID ".1.3.6.1.4.1.24681.1.2.17.1.4.2"
# 1.3.6.1.4.1.24681.1.2.17.1.5.2: NAS-MIB|system volume: 2|sys volume free size
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_2_free_size" -OID ".1.3.6.1.4.1.24681.1.2.17.1.5.2"
# 1.3.6.1.4.1.24681.1.2.17.1.6.2: NAS-MIB|system volume: 2|sys volume status||
Get-SNMPDataInformation -SNMPObj $SNMP -PropertyName "Volume_2_status" -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.2"
#endregion 

Write-Host "-----------------------------------------------------------------------"

#region Comare
try {
    $Vol1RemainingSizeInPercent = [double]$AllSNMPData.Volume_1_free_size.Split(" ")[0] / [double]$AllSNMPData.Volume_1_total_size.Split(" ")[0]
    if ($Vol1RemainingSizeInPercent -lt 0.20) 
    {
        Write-Host "Warning: Not enough space on Volume 1"
        $errorcount++
        Write-Host "-----------------------------------------------------------------------"
    }

    $Vol1RemainingSizeInPercent = [double]$AllSNMPData.Volume_2_free_size.Split(" ")[0] / [double]$AllSNMPData.Volume_2_total_size.Split(" ")[0]
    if ($Vol1RemainingSizeInPercent -lt 0.20) 
    {
        Write-Host "Warning: Not enough space on Volume 2"
        $errorcount++
        Write-Host "-----------------------------------------------------------------------"
    }
}
catch {
    Write-Host "$PSItem.Exception.Message"
}
#endregion

if($goodcount -eq 0)
{
    Write-Host "Es konnten keine Daten erfasst werden."
    Write-Host "Pruefen Sie die SNMP Schnittstelle an der QNAP"    
}