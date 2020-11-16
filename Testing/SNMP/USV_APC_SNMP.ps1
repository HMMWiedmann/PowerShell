<# Variabeln des Automation Manager Skripts
    [string]$IPAdresses
    [string]$CommunityString
#>
#region Konverterfunktionen
function Convert_ups_basic_battery_status
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "1"  {
            return "unknown"
        }
        "2" { 
            return "batteryNormal"
        }
        "3" {
            return "batteryLow"
        }
        "4" {
            return "batteryInFaultCondition"
        }        
        Default {
            "Error: Value not found"
        }
    }
}
function Convert_ups_adv_test_diagnostics_results
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "1"  {
            return "okay"
        }
        "2" { 
            return "failed"
        }
        "3" {
            return "invalidTest"
        }
        "4" {
            return "testInProgress"
        }
        Default {
            "Error: Value not found"
        }
    }
}
function Convert_ups_adv_battery_replace_indicator
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "1"  {
            return "noBatteryNeedsReplacing"
        }
        "2" { 
            return "batteryNeedsReplacing"
        }
        Default {
            "Error: Value not found"
        }
    }
}
function Convert_ups_basic_output_status
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "1" { return "unknown" }
        "2" { return "onLine" }
        "3" { return "onBattery" }
        "4" { return "onSmartBoost" }
        "5" { return "timedSleeping" }
        "6" { return "softwareBypass" }
        "7" { return "off" }
        "8" { return "rebooting" }
        "9" { return "switchedBypass" }
        "10" { return "hardwareFailureBypass" }
        "11" { return "sleepingUntilPowerReturn" }
        "12" { return "onSmartTrim" }
        "13" { return "ecoMode" }
        "14" { return "hotStandby" }
        "15" { return "onBatteryTest" }
        "16" { return "emergencyStaticBypass" }
        "17" { return "staticBypassStandby" }
        "18" { return "powerSavingMode" }
        "19" { return "spotMode" }
        "20" { return "eConversion" }
        "21" { return "chargerSpotmode" }
        "22" { return "inverterSpotmode" }
        "23" { return "activeLoad" }
        "24" { return "batteryDischargeSpotmode" }
        "25" { return "inverterStandby" }
        "26" { return "chargerOnly" }
        Default { "Error: Value not found" }
    }
}
#endregion

[int]$Errorcount = 0

#region SNMP Modul Check
if ($PSVersionTable.PSVersion.Major -ge 5) 
{
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

    if (!(Get-Module -ListAvailable -Name Snmp)) 
    {
        Write-Host "PS-Modul SNMP ist nicht installiert"
        try 
        {
            Write-Host "Versuche PS-Modul SNMP von der PowerShellGallery zu installieren!"
            if (!(Get-PackageProvider -Name NuGet -ListAvailable)) 
            {
                Install-PackageProvider -Name NuGet -Force -Confirm:$false
            }

            Install-Module -Name SNMP -Force -Confirm:$false
        }
        catch 
        {
            Write-Host "Es gab einen Fehler mit dem PS-Modul SNMP"
            Write-Host $PSItem.Exception.Message
            $ErrorCount++
            Exit 1001
        }    
    }
    else {    
        Import-Module SNMP
    }
}
else 
{
    if (Test-Path -path "C:\Program Files\WindowsPowerShell\Modules\SNMP\*\SNMP.psm1") 
    {
        try 
        {
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
            Import-Module "C:\Program Files\WindowsPowerShell\Modules\SNMP\1.0.0.1\SNMP.psm1"
            Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\SNMP\1.0.0.1\SharpSnmpLib.dll"
        }
        catch 
        {
            Write-Host "Es gab einen Fehler beim Importieren des SNMP Moduls"
            Write-Host "Error detail : $($PSItem.Exception.Message)"
            $ErrorCount++
            Exit 1001 
        }        
    }
    else 
    {
        Write-Host "PS-Modul SNMP ist nicht installiert"
        $ErrorCount++
        Exit 1001 
    }
}
#endregion

$IPAdressList = $IPAdresses.split(",")

foreach ($IPAdress in $IPAdressList) 
{
    #region Daten sammeln
    $AllSNMPData = @{}

    $AllSNMPData.Add("ups_basic_ident_model", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.1.1.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_adv_battery_capacity", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.2.2.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_adv_battery_replace_indicator", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.2.2.4.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_adv_battery_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.2.2.2.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_adv_output_load", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.4.2.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_adv_test_diagnostics_results", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.7.2.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_basic_battery_last_replace_date", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.2.1.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_basic_battery_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.2.1.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("ups_basic_output_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.318.1.1.1.4.1.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    #endregion

    #region Daten ueberpruefen
    try
    {
        if ($AllSNMPData.ups_adv_battery_capacity -notlike "*object*" -and $AllSNMPData.ups_adv_battery_capacity -notlike "*instance*") 
        {
            if ([int32]$AllSNMPData.ups_adv_battery_capacity -gt 80)
            {
                Write-Host "Ladestand ist bei $($AllSNMPData.ups_adv_battery_capacity)"
                $Errorcount++
            }
        }
        if ($AllSNMPData.ups_adv_battery_replace_indicator -ne "1")
        {   
            Write-Host "Eine Batterie muss getauscht werden."
            $Errorcount++
        }
        if ($AllSNMPData.ups_adv_battery_temperature -notlike "*object*" -and $AllSNMPData.ups_adv_battery_temperature -notlike "*instance*") 
        {
            if ([int32]$AllSNMPData.ups_adv_battery_temperature -gt 45)
            {
                Write-Host "Batterietemperatur bei $($AllSNMPData.ups_adv_battery_temperature)"
                $Errorcount++
            }
        }
        if ($AllSNMPData.ups_adv_output_load -notlike "*object*" -and $AllSNMPData.ups_adv_output_load -notlike "*instance*") 
        {
            if ([int32]$AllSNMPData.ups_adv_output_load -gt 80)
            {
                Write-Host "Auslastung ist bei $($AllSNMPData.ups_adv_output_load) %"
                $Errorcount++
            }
        }
        if ($AllSNMPData.ups_adv_test_diagnostics_results -ne "1")
        {   
            Write-Host "Ein Test hat einen Fehler. Details:`n" (Convert_ups_adv_test_diagnostics_results -SNMPValue $AllSNMPData.ups_adv_test_diagnostics_results)
            $Errorcount++
        }
        if ($AllSNMPData.ups_basic_battery_status -ne "1")
        {   
            Write-Host "Ein Fehler beim Batteriezustand. Details:`n" (Convert_ups_basic_battery_status -SNMPValue $AllSNMPData.ups_basic_battery_status)
            $Errorcount++
        }
        if ($AllSNMPData.ups_basic_output_status -ne "2")
        {   
            Write-Host "Ein Fehler beim Output. Details:`n" (Convert_ups_basic_output_status -SNMPValue $AllSNMPData.ups_basic_output_status)
            $Errorcount++
        }

        # Last Replace Date Überprüfung einfügen

    }
    catch {
        Write-Host $PSItem.Exception.Message
    }

    if ($ErrorCount -gt 0) 
    {
        Write-Host ""
        Write-Host ""
    }
    #endregion

    #region Daten ausgeben
    Write-Host "------------------------------------------------------------"
    Write-Host "ups_basic_ident_model               : " ($AllSNMPData.ups_basic_ident_model)
    Write-Host "ups_adv_battery_capacity            : " ($AllSNMPData.ups_adv_battery_capacity) "%"
    Write-Host "ups_adv_battery_replace_indicator   : " (Convert_ups_adv_battery_replace_indicator -SNMPValue $AllSNMPData.ups_adv_battery_replace_indicator)
    Write-Host "ups_adv_battery_temperature         : " ($AllSNMPData.ups_adv_battery_temperature)
    Write-Host "ups_adv_output_load                 : " ($AllSNMPData.ups_adv_output_load) "%"
    Write-Host "ups_adv_test_diagnostics_results    : " (Convert_ups_adv_test_diagnostics_results -SNMPValue $AllSNMPData.ups_adv_test_diagnostics_results) 
    Write-Host "ups_basic_battery_last_replace_date : " ($AllSNMPData.ups_basic_battery_last_replace_date)
    Write-Host "ups_basic_battery_status            : " (Convert_ups_basic_battery_status -SNMPValue $AllSNMPData.ups_basic_battery_status)
    Write-Host "ups_basic_output_status             : " (Convert_ups_basic_output_status -SNMPValue $AllSNMPData.ups_basic_output_status)
    Write-Host "------------------------------------------------------------"
    Write-Host ""
    Write-Host ""
    #endregion
}