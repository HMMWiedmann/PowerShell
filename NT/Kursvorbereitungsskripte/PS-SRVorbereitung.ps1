$State = Get-windowsFeature -Name RSAT-AD-PowerShell
if ($State -ne "Installed") 
{
    Install-WindowsFeature -Name RSAT-AD-PowerShell
}

$Computers = (Get-ADComputer -Filter {(Name -like "SV*")}).DNSHostName

$DomainName = "ADS-Center.de"
$CredDomainUser = "T1-ServerAdmin@$DomainName"
$CredDomainPW = ConvertTo-SecureString -String "C0mplex" -AsPlainText -Force
$DomCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CredDomainUser, $CredDomainPW

ForEach( $Comp in $Computers)
{ 
    Invoke-Command -ComputerName $Comp -Credential $DomCred -ScriptBlock{  

        $VM = Get-VM -Name "VM*-01"

        if ($VM.State -eq "Off") 
        {
            Start-VM -VM $VM -Confirm:$false
        }

        $DiskSize1 = 40GB
        $DiskSize2 = 20GB

        New-VHD -Path "V:\$($VM.Name)\$($DiskSize1).vhdx" -SizeBytes $DiskSize1
        Add-VMHardDiskDrive -VMName $VM.Name -Path "V:\$($VM.Name)\$($DiskSize1).vhdx" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2

        New-VHD -Path "V:\$($VM.Name)\$($DiskSize2).vhdx" -SizeBytes $DiskSize2
        Add-VMHardDiskDrive -VMName $VM.Name -Path "V:\$($VM.Name)\$($DiskSize2).vhdx"-ControllerType SCSI -ControllerNumber 0 -ControllerLocation 3

        Invoke-Command -ComputerName $VM.Name -Credential $using:DomCred -ScriptBlock{
            (Get-Disk).where{ $PSItem.Size -eq $using:DiskSize1} | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter S -UseMaximumSize | Format-Volume -FileSystem ReFS
            (Get-Disk).where{ $PSItem.Size -eq $using:DiskSize2} | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter L -UseMaximumSize | Format-Volume -FileSystem ReFS 
        }
    }
}