<# Variabeln des Automation Manager Skripts
    $IPAdresses
    $CommunityString
#>

<# Todo
    - Softwareversion QNAP, Netgear, Synology
    - Sofwareversionscheck auf aktualität
    - eventuell Modelle einpflegen
#>

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

[int]$errorcount = 0

$IPAdressList = $IPAdresses.split(",")

foreach ($IPAdress in $IPAdressList) 
{
    $AllSNMPData = @{}

    [bool]$DiskCountCheck = $false
    [int]$DiskCount = 0
    [int]$Diski = 0

    while ($DiskCountCheck -eq $false)
    {
        for ($Diski = 1; $Diski -lt 9; $Diski++)
        { 
            $Value = (Get-SnmpData -IP $IPAdress -OID (".1.3.6.1.4.1.4526.22.3.1.1." + $Diski) -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data
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
        for ($Voli = 1; $Voli -lt 9; $Voli++)
        { 
            $Value = (Get-SnmpData -IP $IPAdress -OID (".1.3.6.1.4.1.4526.22.7.1.1." + $Voli) -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data
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

    # HDD Infos
    $AllSNMPData.Add("disk_state_1", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("disk_temp_1", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    if ($DiskCount -eq 2) 
    {
        $AllSNMPData.Add("disk_state_2", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("disk_temp_2", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        
        if ($DiskCount -eq 4) 
        {
            $AllSNMPData.Add("disk_state_3", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
            $AllSNMPData.Add("disk_temp_3", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.3" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

            $AllSNMPData.Add("disk_state_4", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.9.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
            $AllSNMPData.Add("disk_temp_4", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.3.1.10.4" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        }
        elseif ($DiskCount -gt 4)
        {
            Write-Host "Es gibt vermutlich mehr als vier Disks"
        }            
    }

    # System Infos
    $AllSNMPData.Add("nas_os_version", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.1.0" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    # Volume Infos
    $AllSNMPData.Add("volume_1_free_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.7.1.6.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("volume_1_total_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.7.1.5.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    $AllSNMPData.Add("volume_1_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.7.1.4.1" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)

    if ($VolumeCount -eq 2) 
    {
        $AllSNMPData.Add("volume_2_free_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.7.1.6.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("volume_2_total_size_in_MB", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.7.1.5.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
        $AllSNMPData.Add("volume_2_status", (Get-SnmpData -IP $IPAdress -OID ".1.3.6.1.4.1.4526.22.7.1.4.2" -Community $CommunityString -Version V2 -ErrorAction SilentlyContinue).Data)
    }
    elseif ($VolumeCount -gt 2)
    {
        Write-Host "Es gibt vermutlich mehr als zwei Volumen, bitte pruefen"
        $ErrorCount++
    }

    try 
    {
        # HDD disk state
        if ($AllSNMPData.disk_state_1 -ne "ONLINE") 
        {
            Write-Host "disk_state_1 hat einen Fehler gemeldet"
            $ErrorCount++
        }
        if ($DiskCount -eq 2)
        {
            if ($AllSNMPData.disk_state_2 -ne "ONLINE") 
            {
                Write-Host "disk_state_2 hat einen Fehler gemeldet"
                $ErrorCount++
            }
            if ($DiskCount -eq 4) 
            {
                if ($AllSNMPData.disk_state_3 -ne "ONLINE") 
                {
                    Write-Host "disk_state_3 hat einen Fehler gemeldet"
                    $ErrorCount++
                }                    
                if ($AllSNMPData.disk_state_4 -ne "ONLINE") 
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
        if ($AllSNMPData.volume_1_free_size_in_MB -ne "NoSuchObject" -or $AllSNMPData.volume_1_total_size_in_MB -ne "NoSuchInstance")
        {
            if ([int64]$AllSNMPData.volume_1_free_size_in_MB -lt 3092) 
            {
                Write-Host "Volumen 1 ist fast voll"
                $ErrorCount++
            }
        }            
        if ($AllSNMPData.volume_1_status -ne "REDUNDANT") 
        {
            Write-Host "volume_1_status hat einen Fehler gemeldet"
            $ErrorCount++
        }

        if ($VolumeCount -eq 2) 
        {
            if ($AllSNMPData.volume_2_total_size_in_MB -ne "NoSuchObject" -or $AllSNMPData.volume_2_total_size_in_MB -ne "NoSuchInstance")
            {
                if ([int64]$AllSNMPData.volume_2_free_size_in_MB -lt 3092) 
                {
                    Write-Host "Volumen 2 ist fast voll"
                    $ErrorCount++
                }
            }
            if ($AllSNMPData.volume_2_status -ne "REDUNDANT") 
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
    Write-Host "disk_state_1 : " ($AllSNMPData.disk_state_1)
    Write-Host "disk_temp_1 :  " $disk_temp_1
    Write-Host "-----------------------------------------"
    if ($DiskCount -eq 2) 
    {
        Write-Host "disk_state_2 : " ($AllSNMPData.disk_state_2)
        Write-Host "disk_temp_2 :  " $disk_temp_2
        Write-Host "-----------------------------------------"
        
        if ($DiskCount -eq 4) 
        {
            Write-Host "disk_state_3 : " ($AllSNMPData.disk_state_3)
            Write-Host "disk_temp_3 :   " $disk_temp_3
            Write-Host "-----------------------------------------"
            Write-Host "disk_state_4 : " ($AllSNMPData.disk_state_4)
            Write-Host "disk_temp_4 :   " $disk_temp_4
            Write-Host "-----------------------------------------"
        }    
    }
    Write-Host "nas_os_version: " ($AllSNMPData.nas_os_version)
    Write-Host "volume_1_free_size_in_MB :  " ($AllSNMPData.volume_1_free_size_in_MB)
    Write-Host "volume_1_total_size_in_MB : " ($AllSNMPData.volume_1_total_size_in_MB)
    if ($AllSNMPData.volume_1_free_size_in_MB -ne "NoSuchObject" -and $AllSNMPData.volume_1_total_size_in_MB -ne "NoSuchObject")
    {
        if ($AllSNMPData.volume_1_free_size_in_MB -ne "NoSuchInstance" -and $AllSNMPData.volume_1_total_size_in_MB -ne "NoSuchInstance")
        {
            Write-Host "volume_1_remaining_size_in_% : " ($AllSNMPData.volume_1_free_size_in_MB / $AllSNMPData.volume_1_total_size_in_MB * 100)
        }
    }
    Write-Host "volume_1_status : " ($AllSNMPData.volume_1_status)
    Write-Host "-----------------------------------------"
    if ($VolumeCount -eq 2)
    {
        if ($AllSNMPData.volume_2_free_size_in_MB -ne "NoSuchObject" -and $AllSNMPData.volume_2_total_size_in_MB -ne "NoSuchObject") 
        {
            if ($AllSNMPData.volume_2_free_size_in_MB -ne "NoSuchInstance" -and $AllSNMPData.volume_2_total_size_in_MB -ne "NoSuchInstance") 
            {
                Write-Host "volume_2_remaining_size_in_% : " ($AllSNMPData.volume_2_free_size_in_MB / $AllSNMPData.volume_2_total_size_in_MB * 100)
                Write-Host "volume_2_free_size_in_MB :  " ($AllSNMPData.volume_2_free_size_in_MB)
                Write-Host "volume_2_total_size_in_MB : " ($AllSNMPData.volume_2_total_size_in_MB)
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