<# Variabeln des Automation Manager Skripts
    $IPAdress
    $CommunityString
#>

<# Todo
    - Softwareversion QNAP, Netgear, Synology
    - Sofwareversionscheck auf aktualität
    - eventuell Modelle einpflegen
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

[int]$errorcount = 0

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



$IPAdressList = $IPAdresses.split(",")

foreach ($IPAdress in $IPAdressList) 
{

    $AllSNMPData = @{}

    try 
    {
        [int]$DiskCount = (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.10.0" -Community $CommunityString -Version V2).Data
        [int]$VolumeCount = (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.16.0" -Community $CommunityString -Version V2).Data    
    }    
    catch 
    {        
        Write-Host $PSItem.Exception.Message
        $ErrorCount++
        Exit 1001
    }        

    # System Infos
    $AllSNMPData.Add("system_hostname", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.13.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("system_model", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.12.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    # $AllSNMPData.Add("system_cpu_usage", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("system_temperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    # HDD Infos
    $AllSNMPData.Add("hdd_1_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("hdd_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    if ($DiskCount -ge 2) 
    {
        $AllSNMPData.Add("hdd_2_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("hdd_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        
        if ($DiskCount -eq 4) 
        {
            $AllSNMPData.Add("hdd_3_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
            $AllSNMPData.Add("hdd_3_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

            $AllSNMPData.Add("hdd_4_smart_info", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.7.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
            $AllSNMPData.Add("hdd_4_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.11.1.4.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        }
        elseif ($DiskCount -gt 4)
        {
            Write-Host "Es gibt vermutlich mehr als vier Disks"
        }
    }

    # Volume Infos
    $AllSNMPData.Add("volume_1_free_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.17.1.5.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("volume_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("volume_1_total_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.17.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    if ($VolumeCount -eq 2) 
    {
        $AllSNMPData.Add("volume_2_free_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.17.1.5.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("volume_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.2.17.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("volume_2_total_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.24681.1.3.17.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    }
    elseif ($VolumeCount -gt 2)
    {
        Write-Host "Es gibt vermutlich mehr als zwei Volumen, bitte pruefen"
        $ErrorCount++
    }

    try 
    {
        # HDD Info Check
        if ($AllSNMPData.hdd_1_smart_info -ne "GOOD" -or $AllSNMPData.hdd_1_status -ne "0") 
        {
            Write-Host "HDD 1 hat einen Fehler"
            $ErrorCount++
        }
        if ($DiskCount -ge 2)
        {
            if ($AllSNMPData.hdd_2_status -ne "-5" -or $AllSNMPData.hdd_2_smart_info -notlike "*--*") 
            {
                if ($AllSNMPData.hdd_2_status -ne "0" -or $AllSNMPData.hdd_2_smart_info -ne "GOOD") 
                {
                    Write-Host "HDD2 hat einen Fehler"
                    $ErrorCount++
                }
            }

            if ($DiskCount -ge 4)
            {
                if ($AllSNMPData.hdd_3_status -ne "-5" -or $AllSNMPData.hdd_3_smart_info -notlike "*--*") 
                {
                    if ($AllSNMPData.hdd_3_status -ne "0" -or $AllSNMPData.hdd_3_smart_info -ne "GOOD") 
                    {
                        Write-Host "HDD3 hat einen Fehler"
                        $ErrorCount++
                    }
                }                

                if ($AllSNMPData.hdd_4_status -ne "-5" -or $AllSNMPData.hdd_4_smart_info -notlike "*--*") 
                {
                    if ($AllSNMPData.hdd_4_status -ne "0" -or $AllSNMPData.hdd_4_smart_info -ne "GOOD") 
                    {
                        Write-Host "HDD4 hat einen Fehler"
                        $ErrorCount++
                    }
                }
            }
        }          

        # System Status
        <#
        if ($null -ne $AllSNMPData.system_cpu_usage)
        {
            if ([int32]$AllSNMPData.system_cpu_usage -gt 70) 
            {
                Write-Host "system_cpu_usage hat einen Fehler gemeldet"
                $ErrorCount++
            }
        }
        #>
        
        if ($null -ne $AllSNMPData.system_temperature) 
        {
            if ([int32]$AllSNMPData.system_temperature -gt 50) 
            {
                Write-Host "system_temperature hat einen Fehler gemeldet"
                $ErrorCount++
            }
        }

        # Volume Status
        if ($AllSNMPData.volume_1_free_size_in_MB -notlike "*object*" -and $AllSNMPData.volume_1_free_size_in_MB -notlike "*Instance*")
        {
            if ($AllSNMPData.volume_1_total_size_in_GB -notlike "*object*" -and $AllSNMPData.volume_1_total_size_in_GB -notlike "*Instance*")
            {
                $AvailableSpaceVol1 = ($AllSNMPData.volume_1_free_size_in_MB / $AllSNMPData.volume_1_total_size_in_MB * 100)
                if ([int64]$AllSNMPData.volume_1_free_size_in_MB -lt 314572800 -and $AvailableSpaceVol1 -lt 20) 
                {
                    Write-Host "Volumen 1 ist fast voll"
                    $ErrorCount++
                }                
            }            
        }
        if ($AllSNMPData.volume_1_status -ne "Ready") 
        {
            Write-Host "volume_1_status hat einen Fehler gemeldet"
            $ErrorCount++
        }

        if ($VolumeCount -eq 2) 
        {
            if ($AllSNMPData.volume_2_total_size_in_MB -notlike "*object*" -and $AllSNMPData.volume_2_total_size_in_MB -notlike "*Instance*")
            {
                if ($AllSNMPData.volume_2_free_size_in_GB -notlike "*object*" -and $AllSNMPData.volume_2_free_size_in_GB -notlike "*Instance*")
                {
                    $AvailableSpaceVol2 = ($AllSNMPData.volume_2_free_size_in_MB / $AllSNMPData.volume_2_total_size_in_MB * 100)
                    if ([int64]$AllSNMPData.volume_2_free_size_in_MB -lt 314572800 -and $AvailableSpaceVol2 -lt 20) 
                    {
                        Write-Host "Volumen 2 ist fast voll"
                        $ErrorCount++
                    }       
                }
            }
            if ($AllSNMPData.volume_2_status -ne "Ready") 
            {
                Write-Host "volume_2_status hat einen Fehler gemeldet"
                $ErrorCount++
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

    # Daten ausgeben
    Write-Host "-----------------------------------------"
    Write-Host "system_hostname       : " ($AllSNMPData.system_hostname)
    # Write-Host "system_cpu_usage      : " ($AllSNMPData.system_cpu_usage)
    Write-Host "system_temperature    : " ($AllSNMPData.system_temperature)
    Write-Host "system_model          : " ($AllSNMPData.system_model)
    Write-Host "system_anzahl_disks   : " $DiskCount
    Write-Host "system_anzahl_volumen : " $VolumeCount
    Write-Host "-----------------------------------------"
    Write-Host "hdd_1_smart_info : " ($AllSNMPData.hdd_1_smart_info)
    Write-Host "hdd_1_status     : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_1_status)
    Write-Host "-----------------------------------------"
    if ($DiskCount -ge 2) 
    {
        Write-Host "hdd_2_smart_info : " ($AllSNMPData.hdd_2_smart_info)
        Write-Host "hdd_2_status     : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_2_status)
        Write-Host "-----------------------------------------"

        if ($DiskCount -eq 4)
        {
            Write-Host "hdd_3_smart_info : " ($AllSNMPData.hdd_3_smart_info)
            Write-Host "hdd_3_status     : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_3_status)
            Write-Host "-----------------------------------------"
            Write-Host "hdd_4_smart_info : " ($AllSNMPData.hdd_4_smart_info)
            Write-Host "hdd_4_status     : " (Convert_hdd_status_to_text -SNMPValue $AllSNMPData.hdd_4_status)
            Write-Host "-----------------------------------------"
        }    
    }
    if ($AllSNMPData.volume_1_free_size_in_MB -notlike "*object*" -and $AllSNMPData.volume_1_free_size_in_MB -notlike "*object*")
    {
        if ($AllSNMPData.volume_1_total_size_in_MB -notlike "*Instance*" -and $AllSNMPData.volume_1_total_size_in_MB -notlike "*Instance*")
        {
            Write-Host "volume_1_free_size_in_GB     : " ("{0:N2}" -f ($AllSNMPData.volume_1_free_size_in_MB /1mb))
            Write-Host "volume_1_total_size_in_GB    : " ("{0:N2}" -f ($AllSNMPData.volume_1_total_size_in_MB /1mb))
            Write-Host "volume_1_remaining_size_in_% : " ("{0:N2}" -f $AvailableSpaceVol1)
        }
    }
    Write-Host "volume_1_status : " ($AllSNMPData.volume_1_status)
    Write-Host "-----------------------------------------"
    if ($VolumeCount -eq 2)
    {        
        if ($AllSNMPData.volume_2_free_size_in_MB -notlike "*object*" -and $AllSNMPData.volume_2_free_size_in_MB -notlike "*object*") 
        {
            if ($AllSNMPData.volume_2_total_size_in_MB -notlike "*Instance*" -and $AllSNMPData.volume_2_total_size_in_MB -notlike "*Instance*") 
            {
                Write-Host "volume_2_free_size_in_GB     : " ("{0:N2}" -f ($AllSNMPData.volume_2_free_size_in_MB /1mb))
                Write-Host "volume_2_total_size_in_GB    : " ("{0:N2}" -f ($AllSNMPData.volume_2_total_size_in_MB /1mb))                    
                Write-Host "volume_2_remaining_size_in_% : " ("{0:N2}" -f $AvailableSpaceVol2)
            }
            else 
            {
                Write-Host "Volume 2 kann nicht ausgelesen werden"
                $ErrorCount++
            }     
        }
        else
        {
            Write-Host "Volume 2 kann nicht ausgelesen werden"
            $ErrorCount++
        }
        Write-Host "volume_2_status : " ($AllSNMPData.volume_2_status)
        Write-Host "-----------------------------------------"
    }
    Write-Host ""
    Write-Host ""
}