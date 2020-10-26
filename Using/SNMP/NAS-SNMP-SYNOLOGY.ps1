<# Variabeln des Automation Manager Skripts
    $IPAdresses
    $CommunityString
#>

<# Todo
    - Softwareversion QNAP, Netgear, Synology
    - Sofwareversionscheck auf aktualität
    - eventuell Modelle einpflegen
#>

function Convert_disk_status_to_text
{
    param (
        # Wert dem SNMP zurueck gibt
        [Parameter(Mandatory = $true)]
        [string]$SNMPValue
    )
    
    switch ($SNMPValue) 
    {
        "1" {
            return "Normal"
        }
        "2" {
            return "Initialized"
        }
        "3" {
            return "NotInitialized"
        }
        "4" {
            return "SystemPartitionFailed"
        }
        "5"{
            return "Crashed"
        }
        Default {
            "unknown"
        }
    }
}

if ($PSVersionTable.PSVersion.Major -lt 5) 
{
    Write-Host "Bitte installieren sie WMF 5.1 fuer das entsprechende System."
    Write-Host "Es wird die PowerShell 5.0 oder 5.1 benoetigt!"
    $ErrorCount++
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
        $ErrorCount++
        Exit 1001
    }    
}
else {    
    Import-Module SNMP
}

$IPAdressList = $IPAdresses.split(",")

foreach ($IPAdress in $IPAdressList) 
{
    [int]$errorcount = 0
    $AllSNMPData = @{}

    #region get disk and volume count
    [bool]$DiskCountCheck = $false
    [int]$DiskCount = 0
    [int]$Diski = 0

    while ($DiskCountCheck -eq $false)
    {
        for ($Diski = 0; $Diski -lt 8; $Diski++)
        { 
            $Value = (Get-SnmpData -IP $IPAdress -OID (".1.3.6.1.4.1.6574.2.1.1.5." + $Diski) -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data
            if ($value -like "*instance*" -or $Value -like "*object*")
            {
                $DiskCountCheck = $true
            }
            else
            {
                $DiskCount++
            }
        }
    }

    [bool]$VolumeCountCheck = $false
    [int]$VolumeCount = 0
    [int]$Voli = 0

    while ($VolumeCountCheck -eq $false)
    {
        for ($Voli = 0; $Voli -lt 2; $Voli++)
        { 
            $Value = (Get-SnmpData -IP $IPAdress -OID (".1.3.6.1.4.1.6574.3.1.1.3." + $Voli) -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data
            if ($value -like "*instance*" -or $Value -like "*object*")
            {
                $VolumeCountCheck = $true
            }
            else
            {
                $VolumeCount++
            }
        }
    }
    #endregion

    #region System Infos
    $AllSNMPData.Add("nas_modelName", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.1.5.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("nas_upgradeavailable", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.1.5.4.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("nas_os_version", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.1.5.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("nas_systemstatus", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.1.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("nas_systemtemperature", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.1.2.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    #endregion

    #region Disk Infos
    $AllSNMPData.Add("disk_state_1", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.5.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("disk_temp_1", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.6.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    if ($DiskCount -eq 2) 
    {
        $AllSNMPData.Add("disk_state_2", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.5.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("disk_temp_2", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        
        if ($DiskCount -eq 4) 
        {
            $AllSNMPData.Add("disk_state_3", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.5.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
            $AllSNMPData.Add("disk_temp_3", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

            $AllSNMPData.Add("disk_state_4", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.5.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
            $AllSNMPData.Add("disk_temp_4", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.2.1.1.6.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        }
        elseif ($DiskCount -gt 4)
        {
            Write-Host "Es gibt vermutlich mehr als vier Disks"
        }            
    }
    #endregion

    #region Volume Infos
    $AllSNMPData.Add("raid_1_FreeSize_in_B", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.3.1.1.4.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("raid_1_TotalSize_in_B", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.3.1.1.5.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("raid_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.3.1.1.3.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    if ($VolumeCount -eq 2) 
    {
        $AllSNMPData.Add("raid_2_FreeSize_in_B", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.3.1.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("raid_2_TotalSize_in_B", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.3.1.1.5.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("raid_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.6574.3.1.1.3.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    }
    elseif ($VolumeCount -gt 2)
    {
        Write-Host "Es gibt vermutlich mehr als zwei Volumen, bitte pruefen"
        $ErrorCount++
    }
    #endregion

    #region check values
    try 
    {
        # System 
        if ($AllSNMPData.nas_upgradeavailable -ne "2") 
        {
            if ($AllSNMPData.nas_upgradeavailable -eq "1") 
            {
                Write-Host "Es ist ein neues DSM Update verfügbar"
            }            
        }
        if ($AllSNMPData.nas_systemstatus -ne "1" -or $AllSNMPData.nas_systemtemperature -gt "50") 
        {
            Write-Host "Das System meldet einen Fehler"
            $ErrorCount++
        }

        # HDD disk state
        if ($AllSNMPData.disk_state_1 -ne "1") 
        {
            Write-Host "disk_state_1 hat einen Fehler gemeldet"
            $ErrorCount++
        }
        if ($DiskCount -eq 2)
        {
            if ($AllSNMPData.disk_state_2 -ne "1") 
            {
                Write-Host "disk_state_2 hat einen Fehler gemeldet"
                $ErrorCount++
            }
            if ($DiskCount -eq 4) 
            {
                if ($AllSNMPData.disk_state_3 -ne "1") 
                {
                    Write-Host "disk_state_3 hat einen Fehler gemeldet"
                    $ErrorCount++
                }                    
                if ($AllSNMPData.disk_state_4 -ne "1") 
                {
                    Write-Host "disk_state_4 hat einen Fehler gemeldet"
                    $ErrorCount++
                }
            }                
        }

        # HDD temp
        [int]$disk_temp_1 = $AllSNMPData.disk_temp_1
        if ($disk_temp_1 -gt 50) 
        {
            Write-Host "disk_temp_1 hat einen Fehler gemeldet"
            $ErrorCount++
        }
        if ($DiskCount -eq 2) 
        {
            [int]$disk_temp_2 = $AllSNMPData.disk_temp_2
            if ($disk_temp_2 -gt 50) 
            {
                Write-Host "disk_temp_2 hat einen Fehler gemeldet"
                $ErrorCount++
            }            
            if ($DiskCount -eq 4) 
            {
                [int]$disk_temp_3 = $AllSNMPData.disk_temp_3                    
                if ($disk_temp_3 -gt 50) 
                {
                    Write-Host "disk_temp_3 hat einen Fehler gemeldet"
                    $ErrorCount++
                }
                [int]$disk_temp_4 = $AllSNMPData.disk_temp_4
                if ($disk_temp_4 -gt 50) 
                {
                    Write-Host "disk_temp_4 hat einen Fehler gemeldet"
                    $ErrorCount++
                }
            }
        }            

        # Volume Status

        if ($AllSNMPData.raid_1_FreeSize_in_B -ne "*object*" -or $AllSNMPData.raid_1_TotalSize_in_B -ne "*instance*")
        {
            if ([int64]$AllSNMPData.raid_1_FreeSize_in_B -lt 322122547200) 
            {
                Write-Host "Volumen 1 ist fast voll"
                $ErrorCount++
            }
        }              
        if ($AllSNMPData.raid_1_status -ne "1") 
        {
            Write-Host "raid_1_status hat einen Fehler gemeldet"
            $ErrorCount++
        }

        if ($VolumeCount -eq 2) 
        {
            if ($AllSNMPData.raid_2_TotalSize_in_B -ne "*object*" -or $AllSNMPData.raid_2_TotalSize_in_B -ne "*instance*")
            {
                if ([int64]$AllSNMPData.raid_2_FreeSize_in_B -lt 322122547200) 
                {
                    Write-Host "Volumen 2 ist fast voll"
                    $ErrorCount++
                }
            }
            if ($AllSNMPData.raid_2_status -ne "1") 
            {
                Write-Host "raid_2_status hat einen Fehler gemeldet"
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
    #endregion

    #region Daten ausgeben
    Write-Host "-----------------------------------------"
    Write-Host "nas_modelName:  " ($AllSNMPData.nas_modelName)
    Write-Host "nas_os_version: " ($AllSNMPData.nas_os_version)
    Write-Host "nas_upgradeavailable: " ($AllSNMPData.nas_upgradeavailable)
    Write-Host "nas_systemstatus: " ($AllSNMPData.nas_systemstatus)
    Write-Host "nas_systemtemperature: " ($AllSNMPData.nas_systemtemperature)

    Write-Host "-----------------------------------------"
    Write-Host "disk_state_1 : " (Convert_disk_status_to_text -SNMPValue $AllSNMPData.disk_state_1)
    Write-Host "disk_temp_1 :  " $disk_temp_1
    Write-Host "-----------------------------------------"
    if ($DiskCount -eq 2) 
    {
        Write-Host "disk_state_2 : " (Convert_disk_status_to_text -SNMPValue $AllSNMPData.disk_state_2)
        Write-Host "disk_temp_2 :  " $disk_temp_2
        Write-Host "-----------------------------------------"
        
        if ($DiskCount -eq 4) 
        {
            Write-Host "disk_state_3 : " (Convert_disk_status_to_text -SNMPValue $AllSNMPData.disk_state_3)
            Write-Host "disk_temp_3 :   " $disk_temp_3
            Write-Host "-----------------------------------------"
            Write-Host "disk_state_4 : " (Convert_disk_status_to_text -SNMPValue $AllSNMPData.disk_state_4)
            Write-Host "disk_temp_4 :   " $disk_temp_4
            Write-Host "-----------------------------------------"
        }    
    }    
    Write-Host "raid_1_FreeSize_in_B :  " ($AllSNMPData.raid_1_FreeSize_in_B)
    Write-Host "raid_1_TotalSize_in_B : " ($AllSNMPData.raid_1_TotalSize_in_B)
    if ($AllSNMPData.raid_1_FreeSize_in_B -ne "*object*" -and $AllSNMPData.raid_1_TotalSize_in_B -ne "*object*")
    {
        if ($AllSNMPData.raid_1_FreeSize_in_B -ne "*instance*" -and $AllSNMPData.raid_1_TotalSize_in_B -ne "*instance*")
        {
            Write-Host "volume_1_remaining_size_in_% : " ($AllSNMPData.raid_1_FreeSize_in_B / $AllSNMPData.raid_1_TotalSize_in_B * 100)
        }
    }
    Write-Host "raid_1_status : " ($AllSNMPData.raid_1_status)
    Write-Host "-----------------------------------------"
    if ($VolumeCount -eq 2)
    {
        if ($AllSNMPData.raid_2_FreeSize_in_B -ne "*object*" -and $AllSNMPData.raid_2_TotalSize_in_B -ne "*object*") 
        {
            if ($AllSNMPData.raid_2_FreeSize_in_B -ne "*instance*" -and $AllSNMPData.raid_2_TotalSize_in_B -ne "*instance*") 
            {
                Write-Host "volume_2_remaining_size_in_% : " ($AllSNMPData.raid_2_FreeSize_in_B / $AllSNMPData.raid_2_TotalSize_in_B * 100)
                Write-Host "raid_2_FreeSize_in_B :  " ($AllSNMPData.raid_2_FreeSize_in_B)
                Write-Host "raid_2_TotalSize_in_B : " ($AllSNMPData.raid_2_TotalSize_in_B)
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
        Write-Host "raid_2_status : " ($AllSNMPData.raid_2_status)
        Write-Host "-----------------------------------------"
    }
    Write-Host ""
    Write-Host ""
    #endregion  
}