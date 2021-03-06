﻿<# Variabeln des Automation Manager Skripts
    $IPAdress
    $CommunityString
    $Vendor
    $DiskCount 
#>

function Convert_hdd_status_to_text
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "0" { 
            return "ready"
        }
        "-4" {
            return "unknown"
        }
        "-5" {
            return "noDisk"
        }
        "-6" {
            return "invalid"
        }
        "-9" {
            return "rwError"
        }
        Default {
            "Error: Value not found"
        }
    }
}

if ($PSVersionTable.PSVersion.Major -lt 5) 
{
    Write-Host "Bitte installieren sie WMF 5.1 fuer das entsprechende System."
    Write-Host "Es wird die PowerShell 5.0 oder 5.1 benoetigt!"
    Exit 1001
}   

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
        Exit 1001
    }    
}
else {    
    Import-Module SNMP
}

[int]$errorcount = 0
$AllSNMPData = @{}

switch ($Vendor) 
{
    "QNAP" {
        switch ($DiskCount) 
        {
            "4"
            {
                # HDD Infos
                $AllSNMPData.Add("hdd_1_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("hdd_2_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("hdd_3_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_3_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("hdd_4_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_4_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # System Infos
                $AllSNMPData.Add("system_cpu_usage", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("system_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # Volume Infos
                $AllSNMPData.Add("volume_1_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("volume_2_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)                  
                
                try 
                {
                    if ($AllSNMPData.hdd_1_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_1_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_2_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_2_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }                    
                    if ($AllSNMPData.hdd_3_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_3_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }                    
                    if ($AllSNMPData.hdd_4_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_4_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }

                    if ($AllSNMPData.hdd_1_status -ne "0") 
                    {
                        Write-Host "hdd_1_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_2_status -ne "0") 
                    {
                        Write-Host "hdd_2_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_3_status -ne "0") 
                    {
                        Write-Host "hdd_3_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_4_status -ne "0") 
                    {
                        Write-Host "hdd_4_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }

                    if ($null -ne $AllSNMPData.system_cpu_usage)
                    {
                        if ([int32]$AllSNMPData.system_cpu_usage -gt 70) 
                        {
                            Write-Host "system_cpu_usage hat einen Fehler gemeldet"
                            $ErrorCount++
                        }
                    }
                    if ($null -ne $AllSNMPData.system_temperature) 
                    {
                        if ([int32]$AllSNMPData.system_temperature -gt 50) 
                        {
                            Write-Host "system_temperature hat einen Fehler gemeldet"
                            $ErrorCount++
                        }
                    }

                    if (!($AllSNMPData.volume_1_free_size_in_KB -eq "NoSuchObject")) 
                    {
                        if ([int64]$AllSNMPData.volume_1_free_size_in_KB -lt 3145728) 
                        {
                            Write-Host "Volumen 1 ist fast voll"
                            $ErrorCount++
                        }
                    }
                    if (!($AllSNMPData.volume_2_total_size_in_KB -eq "NoSuchObject")) 
                    {
                        if ([int64]$AllSNMPData.volume_2_free_size_in_KB -lt 3145728) 
                        {
                            Write-Host "Volumen 2 ist fast voll"
                            $ErrorCount++
                        }
                    }

                    if ($AllSNMPData.volume_1_status -ne "Ready") 
                    {
                        Write-Host "volume_1_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.volume_2_status -ne "Ready") 
                    {
                        Write-Host "volume_2_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                }    
                catch {                
                    Write-Host $PSItem.Exception.Message
                }

                # Daten ausgeben
                Write-Host "-----------------------------------------"
                Write-Host "hdd_1_smart_info : " ($AllSNMPData.hdd_1_smart_info)
                Write-Host "hdd_1_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_1_status)
                Write-Host "-----------------------------------------"
                Write-Host "hdd_2_smart_info : " ($AllSNMPData.hdd_2_smart_info)
                Write-Host "hdd_2_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_2_status)
                Write-Host "-----------------------------------------"
                Write-Host "hdd_3_smart_info : " ($AllSNMPData.hdd_3_smart_info)
                Write-Host "hdd_3_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_3_status)
                Write-Host "-----------------------------------------"
                Write-Host "hdd_4_smart_info : " ($AllSNMPData.hdd_4_smart_info)
                Write-Host "hdd_4_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_4_status)
                Write-Host "-----------------------------------------"
                Write-Host "system_cpu_usage : " ($AllSNMPData.system_cpu_usage)
                Write-Host "system_temperature : " ($AllSNMPData.system_temperature)
                Write-Host "-----------------------------------------"
                Write-Host "volume_1_free_size_in_KB : " ($AllSNMPData.volume_1_free_size_in_KB)
                Write-Host "volume_1_total_size_in_KB : " ($AllSNMPData.volume_1_total_size_in_KB)
                if ($AllSNMPData.volume_1_free_size_in_KB -ne "NoSuchObject" -and $AllSNMPData.volume_1_total_size_in_KB -ne "NoSuchObject")
                {
                    Write-Host "volume_1_remaining_size_in_% : " ($AllSNMPData.volume_1_free_size_in_KB / $AllSNMPData.volume_1_total_size_in_KB * 100)
                }
                Write-Host "volume_1_status : " ($AllSNMPData.volume_1_status)
                Write-Host "-----------------------------------------"
                Write-Host "volume_2_free_size_in_KB : " ($AllSNMPData.volume_2_free_size_in_KB)
                Write-Host "volume_2_total_size_in_KB : " ($AllSNMPData.volume_2_total_size_in_KB)
                if ($AllSNMPData.volume_2_free_size_in_KB -ne "NoSuchObject" -and $AllSNMPData.volume_2_total_size_in_KB -ne "NoSuchObject") 
                {
                    Write-Host "volume_2_remaining_size_in_% : " ($AllSNMPData.volume_2_free_size_in_KB / $AllSNMPData.volume_2_total_size_in_KB * 100)
                }
                Write-Host "volume_2_status : " ($AllSNMPData.volume_2_status)
                Write-Host "-----------------------------------------"
            }
            "2" 
            {
                # HDD Infos
                $AllSNMPData.Add("hdd_1_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("hdd_2_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # System Infos
                $AllSNMPData.Add("system_cpu_usage", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("system_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # Volume Infos
                $AllSNMPData.Add("volume_1_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("volume_2_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)                  
                
                try 
                {
                    if ($AllSNMPData.hdd_1_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_1_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_2_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_2_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }                    

                    if ($AllSNMPData.hdd_1_status -ne "0") 
                    {
                        Write-Host "hdd_1_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_2_status -ne "0") 
                    {
                        Write-Host "hdd_2_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }                    

                    if ($null -ne $AllSNMPData.system_cpu_usage)
                    {
                        if ([int32]$AllSNMPData.system_cpu_usage -gt 70) 
                        {
                            Write-Host "system_cpu_usage hat einen Fehler gemeldet"
                            $ErrorCount++
                        }
                    }
                    if ($null -ne $AllSNMPData.system_temperature) 
                    {
                        if ([int32]$AllSNMPData.system_temperature -gt 50) 
                        {
                            Write-Host "system_temperature hat einen Fehler gemeldet"
                            $ErrorCount++
                        }
                    }

                    if (!($AllSNMPData.volume_1_free_size_in_KB -eq "NoSuchObject")) 
                    {
                        if ([int64]$AllSNMPData.volume_1_free_size_in_KB -lt 3145728) 
                        {
                            Write-Host "Volumen 1 ist fast voll"
                            $ErrorCount++
                        }
                    }
                    if (!($AllSNMPData.volume_2_total_size_in_KB -eq "NoSuchObject")) 
                    {
                        if ([int64]$AllSNMPData.volume_2_free_size_in_KB -lt 3145728) 
                        {
                            Write-Host "Volumen 2 ist fast voll"
                            $ErrorCount++
                        }
                    }

                    if ($AllSNMPData.volume_1_status -ne "Ready") 
                    {
                        Write-Host "volume_1_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.volume_2_status -ne "Ready") 
                    {
                        Write-Host "volume_2_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                }    
                catch {                
                    Write-Host $PSItem.Exception.Message
                }

                # Daten ausgeben
                Write-Host "-----------------------------------------"
                Write-Host "hdd_1_smart_info : " ($AllSNMPData.hdd_1_smart_info)
                Write-Host "hdd_1_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_1_status)
                Write-Host "-----------------------------------------"
                Write-Host "hdd_2_smart_info : " ($AllSNMPData.hdd_2_smart_info)
                Write-Host "hdd_2_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_2_status)
                Write-Host "-----------------------------------------"
                Write-Host "system_cpu_usage : " ($AllSNMPData.system_cpu_usage)
                Write-Host "system_temperature : " ($AllSNMPData.system_temperature)
                Write-Host "-----------------------------------------"
                Write-Host "volume_1_free_size_in_KB : " ($AllSNMPData.volume_1_free_size_in_KB)
                Write-Host "volume_1_total_size_in_KB : " ($AllSNMPData.volume_1_total_size_in_KB)
                if ($AllSNMPData.volume_1_free_size_in_KB -ne "NoSuchObject" -and $AllSNMPData.volume_1_total_size_in_KB -ne "NoSuchObject")
                {
                    Write-Host "volume_1_remaining_size_in_% : " ($AllSNMPData.volume_1_free_size_in_KB / $AllSNMPData.volume_1_total_size_in_KB * 100)
                }
                Write-Host "volume_1_status : " ($AllSNMPData.volume_1_status)
                Write-Host "-----------------------------------------"
                Write-Host "volume_2_free_size_in_KB : " ($AllSNMPData.volume_2_free_size_in_KB)
                Write-Host "volume_2_total_size_in_KB : " ($AllSNMPData.volume_2_total_size_in_KB)
                if ($AllSNMPData.volume_2_free_size_in_KB -ne "NoSuchObject" -and $AllSNMPData.volume_2_total_size_in_KB -ne "NoSuchObject") 
                {
                    Write-Host "volume_2_remaining_size_in_% : " ($AllSNMPData.volume_2_free_size_in_KB / $AllSNMPData.volume_2_total_size_in_KB * 100)
                }
                Write-Host "volume_2_status : " ($AllSNMPData.volume_2_status)
                Write-Host "-----------------------------------------"
            }
            "1" 
            {
                # HDD Infos
                $AllSNMPData.Add("hdd_1_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("hdd_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # System Infos
                $AllSNMPData.Add("system_cpu_usage", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("system_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # Volume Infos
                $AllSNMPData.Add("volume_1_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("volume_2_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)                  
                
                try 
                {
                    if ($AllSNMPData.hdd_1_smart_info -ne "GOOD") 
                    {
                        Write-Host "hdd_1_smart_info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }

                    if ($AllSNMPData.hdd_1_status -ne "0") 
                    {
                        Write-Host "hdd_1_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }

                    if ($null -ne $AllSNMPData.system_cpu_usage)
                    {
                        if ([int32]$AllSNMPData.system_cpu_usage -gt 70) 
                        {
                            Write-Host "system_cpu_usage hat einen Fehler gemeldet"
                            $ErrorCount++
                        }
                    }
                    if ($null -ne $AllSNMPData.system_temperature) 
                    {
                        if ([int32]$AllSNMPData.system_temperature -gt 50) 
                        {
                            Write-Host "system_temperature hat einen Fehler gemeldet"
                            $ErrorCount++
                        }
                    }

                    if (!($AllSNMPData.volume_1_free_size_in_KB -eq "NoSuchObject")) 
                    {
                        if ([int64]$AllSNMPData.volume_1_free_size_in_KB -lt 3145728) 
                        {
                            Write-Host "Volumen 1 ist fast voll"
                            $ErrorCount++
                        }
                    }
                    if (!($AllSNMPData.volume_2_total_size_in_KB -eq "NoSuchObject")) 
                    {
                        if ([int64]$AllSNMPData.volume_2_free_size_in_KB -lt 3145728) 
                        {
                            Write-Host "Volumen 2 ist fast voll"
                            $ErrorCount++
                        }
                    }

                    if ($AllSNMPData.volume_1_status -ne "Ready") 
                    {
                        Write-Host "volume_1_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.volume_2_status -ne "Ready") 
                    {
                        Write-Host "volume_2_status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                }    
                catch {                
                    Write-Host $PSItem.Exception.Message
                }

                # Daten ausgeben
                Write-Host "-----------------------------------------"
                Write-Host "hdd_1_smart_info : " ($AllSNMPData.hdd_1_smart_info)
                Write-Host "hdd_1_status : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_1_status)
                Write-Host "-----------------------------------------"
                Write-Host "system_cpu_usage : " ($AllSNMPData.system_cpu_usage)
                Write-Host "system_temperature : " ($AllSNMPData.system_temperature)
                Write-Host "-----------------------------------------"
                Write-Host "volume_1_free_size_in_KB : " ($AllSNMPData.volume_1_free_size_in_KB)
                Write-Host "volume_1_total_size_in_KB : " ($AllSNMPData.volume_1_total_size_in_KB)
                if ($AllSNMPData.volume_1_free_size_in_KB -ne "NoSuchObject" -and $AllSNMPData.volume_1_total_size_in_KB -ne "NoSuchObject")
                {
                    Write-Host "volume_1_remaining_size_in_% : " ($AllSNMPData.volume_1_free_size_in_KB / $AllSNMPData.volume_1_total_size_in_KB * 100)
                }
                Write-Host "volume_1_status : " ($AllSNMPData.volume_1_status)
                Write-Host "-----------------------------------------"
                Write-Host "volume_2_free_size_in_KB : " ($AllSNMPData.volume_2_free_size_in_KB)
                Write-Host "volume_2_total_size_in_KB : " ($AllSNMPData.volume_2_total_size_in_KB)
                if ($AllSNMPData.volume_2_free_size_in_KB -ne "NoSuchObject" -and $AllSNMPData.volume_2_total_size_in_KB -ne "NoSuchObject") 
                {
                    Write-Host "volume_2_remaining_size_in_% : " ($AllSNMPData.volume_2_free_size_in_KB / $AllSNMPData.volume_2_total_size_in_KB * 100)
                }
                Write-Host "volume_2_status : " ($AllSNMPData.volume_2_status)
                Write-Host "-----------------------------------------"
            }
            Default 
            {
                Write-Host "Es wurde eine nicht unterstuetzte Anzahl an Disks angegeben!"
                Exit 1001
            }
        }    
    }
    "Netgear" {
        
        switch ($DiskCount) 
        {
            "4" 
            {
                # HDD Infos
                $AllSNMPData.Add("disk_1_state", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("disk_2_state", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("disk_3_state", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("disk_4_state", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("disk_1_temp", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("disk_2_temp", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("disk_3_temp", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("disk_4_temp", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # System Infos
                $AllSNMPData.Add("system_cpu_usage", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("system_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                # Volume Infos
                $AllSNMPData.Add("volume_1_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_1_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                $AllSNMPData.Add("volume_2_free_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
                $AllSNMPData.Add("volume_2_total_size_in_KB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.4.1.1.1.2.3.2.1.3.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

                try 
                {
                    if ($AllSNMPData.hdd_1_smart_info -ne "GOOD" -or $AllSNMPData.hdd_2_smart_info -ne "GOOD" -or $AllSNMPData.hdd_3_smart_info -ne "GOOD" -or$AllSNMPData.hdd_4_smart_info -ne "GOOD") 
                    {
                        Write-Host "HDD-Smart-Info hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.hdd_1_status -ne "0" -or $AllSNMPData.hdd_2_status -ne "0" -or $AllSNMPData.hdd_3_status -ne "0" -or $AllSNMPData.hdd_4_status -ne "0") 
                    {
                        Write-Host "HDD-Status hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ([int32]$AllSNMPData.system_cpu_usage -gt 70 -or [int32]$AllSNMPData.system_temperature -gt 50) 
                    {
                        Write-Host "Das System hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                    if ([int64]$AllSNMPData.volume_1_free_size_in_KB -lt 3145728 -or [int64]$AllSNMPData.volume_2_free_size_in_KB -lt 3145728) 
                    {
                        Write-Host "Eins der Volumen ist fast voll"
                        $ErrorCount++
                    }
                    if ($AllSNMPData.volume_1_status -ne "Ready" -or $AllSNMPData.volume_2_status -ne "Ready") 
                    {
                        Write-Host "Ein Volumen hat einen Fehler gemeldet"
                        $ErrorCount++
                    }
                }    
                catch {

                    Write-Host $PSItem.Exception.Message
                }

                # Daten ausgeben
                Write-Host "-----------------------------------------"
                Write-Host "hdd_1_smart_info : $($AllSNMPData.hdd_1_smart_info)"
                Write-Host "hdd_1_status : " Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_1_status
                Write-Host "-----------------------------------------"
                Write-Host "hdd_2_smart_info : $($AllSNMPData.hdd_2_smart_info)"
                Write-Host "hdd_1_status : " Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_2_status
                Write-Host "-----------------------------------------"
                Write-Host "hdd_3_smart_info : $($AllSNMPData.hdd_3_smart_info)"
                Write-Host "hdd_1_status : " Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_3_status
                Write-Host "-----------------------------------------"
                Write-Host "hdd_4_smart_info : $($AllSNMPData.hdd_4_smart_info)"
                Write-Host "hdd_1_status : " Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_4_status
                Write-Host "-----------------------------------------"
                Write-Host "system_cpu_usage : $($AllSNMPData.system_cpu_usage)"
                Write-Host "system_temperature : $($AllSNMPData.system_temperature)"
                Write-Host "-----------------------------------------"
                Write-Host "volume_1_free_size_in_KB : $($AllSNMPData.volume_1_free_size_in_KB)"                
                Write-Host "volume_1_total_size_in_KB : $($AllSNMPData.volume_1_total_size_in_KB)"
                Write-Host "volume_1_remaining_size_in_% : $($AllSNMPData.volume_1_free_size_in_KB / $AllSNMPData.volume_1_total_size_in_KB * 100)"
                Write-Host "volume_1_status : $($AllSNMPData.volume_1_status)"
                Write-Host "-----------------------------------------"
                Write-Host "volume_2_free_size_in_KB : $($AllSNMPData.volume_2_free_size_in_KB)"               
                Write-Host "volume_2_total_size_in_KB : $($AllSNMPData.volume_2_total_size_in_KB)"
                Write-Host "volume_2_remaining_size_in_% : $($AllSNMPData.volume_2_free_size_in_KB / $AllSNMPData.volume_2_total_size_in_KB * 100)"
                Write-Host "volume_2_status : $($AllSNMPData.volume_2_status)"
                Write-Host "-----------------------------------------"
            }
            "2" 
            {
                "Wird derzeit noch nicht unterstuetzt"
            }
            "1" 
            {
                "Wird derzeit noch nicht unterstuetzt"
            }
            Default {
                Write-Host "Es wurde eine nicht unterstuetzte Anzahl an Disks angegeben!"
                Exit 1001
            }
        }        
    }
    "Synology" {
        Write-Host "Synology wird derzeit noch nicht unterstuetzt"
        <#
        switch ($DiskCount) 
        {
            "4" {
                "Wird derzeit noch nicht unterstuetzt"
            }
            "2" {
                "Wird derzeit noch nicht unterstuetzt"
            }
            "1" {
                "Wird derzeit noch nicht unterstuetzt"
            }
            Default {
                Write-Host "Es wurde eine nicht unterstuetzte Anzahl an Disks angegeben!"
                Exit 1001
            }
        }
        #>
    }
    Default 
    {
        Write-Host "Der Hersteller wird nicht unterstuetzt"
    }
}