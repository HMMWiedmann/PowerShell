<# Überlegungen
    Pagefilegröße festsetzen auf Ram größe, aber maximal 32GB
    RAM-Dump bei Systemfailure auf Kernal-dump minimieren
#>

#Region Hilfsfunktionen
workflow Copy-Parallel
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]$ParentdiskPath,

        [Parameter(Mandatory = $true)]
        [string]$VMDriveLetter,
    
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$VMNames
    )

    foreach -parallel ($Name in $VMNames) 
    {
        "Copying VM: $Name"
        $null = New-Item -Type Directory -Path "$($VMDriveLetter):\$($Name)" -Force
        Copy-Item -Path $ParentdiskPath -Destination "$($VMDriveLetter):\$($Name)\$($Name).vhdx" -Force
    }
}
function Confirm-VMState 
{
    param 
    (
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [string]
        $VMName,
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [pscredential]
        $VMCredential
    )
    
    While((Invoke-Command -VMName $VMName -Credential $VMCredential { "Test" } -ErrorAction SilentlyContinue) -ne "Test")
    {
         Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 10
}
#endregion

#region Settings der VMs
$CustomerCode = "CW-HM"
$VMNames = "$($CustomerCode)-VDC01", "$($CustomerCode)-VEX01","$($CustomerCode)-VFS01", "$($CustomerCode)-VAP01"
$ParentdiskPath = "C:\Parentdisks\WIN10-1809-x64-EE-Gen2.437.vhdx"
$CPUCount = 4
$Ram = 8GB
$VMSwitchName = "SET"
#endregion

#region Local Server Admin Credentials
[string]$LocalAdmin = "Administrator"
$LocalPWD = ConvertTo-SecureString ($CustomerCode + "SecurePW01!") -AsPlainText -Force
$VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)
#endregion

# VHDXs Kopieren
Copy-Parallel -ParentdiskPath $ParentdiskPath -VMDriveLetter $VMDriveLetter -VMNames $VMNames

#region Kreation und Konfiguration
foreach ($Name in $VMNames)
{
    $null = New-VM -Name $Name -MemoryStartupBytes $Ram -Path V:\ -Generation 2 -VHDPath "V:\$($Name)\$($Name).vhdx" -BootDevice VHD
    Set-VMProcessor -VMName $Name -Count $CPUCount
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VMName $Name) -SwitchName $VMSwitchName
    Start-VM -VMName $Name

    Confirm-VMState -VMName $Name -VMCredential $VMCred
    Invoke-Command -VMName $Name -Credential $VMCred -ScriptBlock{ 
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Rename-Computer -NewName $using:Name -Restart -Force
    }
    Confirm-VMState -VMName $Name -VMCredential $VMCred
}

Checkpoint-VM -VM (Get-VM) -SnapshotName "CleanInstall"