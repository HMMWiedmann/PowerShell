<# Variabeln des Automation Manager Skripts
    [string]$IPAdresses
    [string]$CommunityString
    [bool]$UPSMAN
    [bool]$SNMPAdapter
#>
#region Konverterfunktionen
function Convert_ups_battery_status
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
            return "batteryDepleted"
        }        
        Default {
            "Error: Value not found"
        }
    }
}
function Convert_ups_test_results_summary
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "1"  {
            return "donePass"
        }
        "2" { 
            return "doneWarning"
        }
        "3" {
            return "doneError"
        }
        "4" {
            return "aborted"
        }
        "5" {
            return "inProgress"
        }
        "6" {
            return "noTestInitiated"
        }
        Default {
            "Error: Value not found"
        }
    }
}
function Convert_ups_output_status
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
            return "Ok"
        }
        "3" {
            return "onBattery"
        }
        "4" {
            return "onBypass"
        }
        "5" {
            return "shutdown"
        }
        Default {
            "Error: Value not found"
        }
    }
}
#endregion

[int]$Errorcount = 0

if ($UPSMAN -eq $true -and $SNMPAdapter -eq $true) 
{
    Write-Host "Es wurden falsche Angaben bei den Parametern des Skripts gemacht"
    $ErrorCount++
    Exit 1001
}

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

    if ($SNMPAdapter -eq $true)
    {
        $AllSNMPData.Add("ups_battery_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.2.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_battery_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.2.7.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_estimated_charge_remaining", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.2.4.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_estimated_minutes_remaining", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.2.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_output_percent_load", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.4.4.1.5.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_output_power", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.4.4.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_test_results_detail", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.7.4.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_test_results_summary", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.7.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_test_start_time", ((Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.7.5.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data))
        $AllSNMPData.Add("ups_test_elapsed_time", ((Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.2.1.33.1.7.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data))
    }
    elseif ($UPSMAN -eq $true) 
    {
        $AllSNMPData.Add("ups_ident_model_name", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.1356.1.1.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_battery_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.1356.1.2.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_Battery_Temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.1356.1.2.4.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_battery_capacity", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.1356.1.2.2.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_output_load", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.1356.1.4.2.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("ups_Output_Status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.1356.1.4.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    }
    else 
    {
        Write-Host "Es wurde keine Variante ausgewählt"
        $Errorcount++
        Exit 1001
    }
    #endregion

    #region Daten ueberpruefen

    try
    {
        if($AllSNMPData.ups_battery_status -ne "2")
        {
            Write-Host (Convert_ups_output_status -SNMPValue $AllSNMPData.ups_battery_status)
            $Errorcount++
        }
        if ($AllSNMPData.ups_battery_temperature -notlike "*object*" -and $AllSNMPData.ups_battery_temperature -notlike "*instance*") 
        {
            if ([int32]$AllSNMPData.ups_battery_temperature -gt 45)
            {
                Write-Host "Batterietemperatur bei $($AllSNMPData.ups_battery_temperature)"
                $Errorcount++
            }
        }
        if ($SNMPAdapter -eq $true)
        {
            if ($AllSNMPData.ups_estimated_charge_remaining -notlike "*object*" -and $AllSNMPData.ups_estimated_charge_remaining -notlike "*instance*") 
            {
                if([int32]$AllSNMPData.ups_estimated_charge_remaining -lt 80)
                {
                    Write-Host "Ladestand ist bei $($AllSNMPData.ups_estimated_charge_remaining)"
                    $Errorcount++
                }
            }
            if ($AllSNMPData.ups_output_percent_load -notlike "*object*" -and $AllSNMPData.ups_output_percent_load -notlike "*instance*") 
            {
                if ([int32]$AllSNMPData.ups_output_percent_load -gt 50) 
                {
                    Write-Host "Auslastung ist bei $($AllSNMPData.ups_output_percent_load) %"
                    $Errorcount++
                }
            }
            if ($AllSNMPData.ups_test_results_summary -ne "1")
            {   
                Write-Host "Ein Test hat einen Fehler. Details:`n" (Convert_ups_test_results_summary -SNMPValue $AllSNMPData.ups_test_results_summary)
                $Errorcount++
            }
        }    
        elseif ($UPSMAN -eq $true) 
        {
            if ($AllSNMPData.ups_battery_capacity -notlike "*object*" -and $AllSNMPData.ups_battery_capacity -notlike "*instance*") 
            {
                if([int32]$AllSNMPData.ups_battery_capacity -lt 80)
                {
                    Write-Host "Ladestand ist bei $($AllSNMPData.ups_battery_capacity)"
                    $Errorcount++
                }
            }
            if ($AllSNMPData.ups_output_load -notlike "*object*" -and $AllSNMPData.ups_output_load -notlike "*instance*") 
            {
                if ([int32]$AllSNMPData.ups_output_load -gt 50) 
                {
                    Write-Host "Auslastung ist bei $($AllSNMPData.ups_output_load) %"
                    $Errorcount++
                }
            }
            if ($AllSNMPData.ups_Output_Status -ne "2") 
            {
                Write-Host (Convert_ups_output_status -SNMPValue $AllSNMPData.ups_Output_Status)
            }            
        }    
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
    if ($SNMPAdapter -eq $true)
    {
        Write-Host "-----------------------------------------"
        Write-Host "ups_battery_status              : " (Convert_ups_battery_status -SNMPValue $AllSNMPData.ups_battery_status)
        Write-Host "ups_battery_temperature         : " ($AllSNMPData.ups_battery_temperature)
        Write-Host "ups_estimated_charge_remaining  : " ($AllSNMPData.ups_estimated_charge_remaining) "%"
        Write-Host "ups_estimated_minutes_remaining : " ($AllSNMPData.ups_estimated_minutes_remaining)
        Write-Host "ups_output_percent_load         : " ($AllSNMPData.ups_output_percent_load) "%"
        Write-Host "ups_output_power                : " ($AllSNMPData.ups_output_power)
        Write-Host "ups_test_results_summary        : " (Convert_ups_test_results_summary -SNMPValue $AllSNMPData.ups_test_results_summary)
        Write-Host "ups_test_results_detail         : " ($AllSNMPData.ups_test_results_detail)
        Write-Host "ups_test_start_time             : " ($AllSNMPData.ups_test_start_time)
        Write-Host "ups_test_elapsed_time           : " ($AllSNMPData.ups_test_elapsed_time)
        Write-Host "-----------------------------------------"
    }
    elseif ($UPSMAN -eq $true) 
    {
        Write-Host "-----------------------------------------"
        Write-Host "ups_ident_model_name    : " ($AllSNMPData.ups_ident_model_name)
        Write-Host "ups_battery_status      : " (Convert_ups_battery_status -SNMPValue $AllSNMPData.ups_battery_status)
        Write-Host "ups_Battery_Temperature : " ($AllSNMPData.ups_Battery_Temperature)
        Write-Host "ups_battery_capacity    : " ($AllSNMPData.ups_battery_capacity) "%"
        Write-Host "ups_output_load         : " ($AllSNMPData.ups_output_load) "%"
        Write-Host "ups_Output_Status       : " (Convert_ups_output_status -SNMPValue $AllSNMPData.ups_Output_Status)
        Write-Host "-----------------------------------------"
    }
    Write-Host ""
    Write-Host ""
    #endregion
}