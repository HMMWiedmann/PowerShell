function Set-Kursvorbereitung
{
    [CmdletBinding()]
    param 
    (
        # Path to the CSVList.csv
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$CSVListPath,

        # Path to the Parentdisk
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$ParentDiskPath,

        # Name of the Virtual Switch
        [Parameter(Mandatory = $true, Position = 3)]
        [string]$SwitchName,

        # Specifies the type of the Parentdisk
        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateSet("True","False")]
        [string]$Differential,

        # Parameter help description
        [Parameter(Mandatory = $false, Position = 5)]
        [switch]$ClearOldStoragePool
    )

    dynamicParam
    {
        # Set the dynamic parameters' name
        $ParameterName = 'PhysicalNICs'
            
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = (Get-NetAdapter -Physical).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    Begin
    {
        # Bind the parameter to a friendly variable
        $PhysicalNICs = $PsBoundParameters[$ParameterName]

        # WindowsFeature
        $state = (Get-WindowsFeature -Name Hyper-V).InstallState
        if($state -eq "Available")
        {
            Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
            Write-Host "You have to restart this Computer, because Hyper-V was not installed!"
            break
        }

        # Module laden
        Import-Module -Name Hyper-V

        # laden der anderen Skripte
        
        . "$PSScriptRoot\Funktionen\Add-VMs.ps1"
        . "$PSScriptRoot\Funktionen\New-SET.ps1"
        . "$PSScriptRoot\Funktionen\New-Volume4VMs.ps1"

        # Variabeln setzen
        $InstallationPath = "V:\"

        # alte Pools loeschen
        if ($ClearOldStoragePool) 
        {
            $RemDisk = (Get-Disk).where{ $PSItem.Number -ne "0" }
            Clear-Disk -Number $RemDisk.Number -Confirm:$false -RemoveData

            $RemVDisk = Get-VirtualDisk
            Remove-VirtualDisk -InputObject $RemVDisk -Confirm:$false

            $RemStoragePool = (Get-StoragePool).where{ $PSItem.FriendlyName -ne "Primordial" }
            Set-StoragePool -InputObject $RemStoragePool -IsReadOnly $false
            Remove-StoragePool -InputObject $RemStoragePool -Confirm:$false
        }

        # Funktion zur erstellen der Disk
        New-Volume4VMs -VMDriveLetter $InstallationPath[0]

        # Parentdisk nach V:\Parentdisks kopieren
        if (!($ParentDiskPath -like ($InstallationPath + "Parentdisks\*")))
        {
            if(!(Test-Path ($InstallationPath + "Parentdisks")))
            {
                New-Item -Path ($InstallationPath + "Parentdisks") -ItemType Directory
            }

            $Destination = "$InstallationPath\Parentdisks"
            $item = Get-Item $ParentDiskPath

            Copy-Item -Path $item.FullName -Destination $Destination -Force            
        }

        $PDisk = Get-Item -Path ($InstallationPath + "Parentdisks\$item.Name")
    }
    
    process 
    {
        # VM Switch erstellen
        New-SET -SwitchName $SwitchName `
                -PhysicalNICs $PhysicalNICs `
                -HostVNICName $HostVNICName

        # VMs erstellen und konfigurieren
        Add-VMs -CSVListPath $CSVListPath `
                -ParentdiskPath $PDisk `
                -SwitchName $SwitchName `
                -Differential $Differential `
                -InstallationPath $InstallationPath
    }
    
    end 
    {
        $VMs = Get-VM -Name *
        Write-Host "Those Virtual Machines were created:"
        Write-Host $VMs
    }
}