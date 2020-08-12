Install-WindowsFeature RSAT-AD-PowerShell

$DomainName = "ADS-Center.de"
$CredDomainUser = "T1-ServerTS@$DomainName"
$CredDomainPW = ConvertTo-SecureString -String "C0mplex" -AsPlainText -Force
$DomCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CredDomainUser, $CredDomainPW

$computers = (Get-ADComputer -Filter {(Name -like "SV*")}).DNSHostName

ForEach( $computer in $computers)
{ 
    Invoke-Command -ComputerName $computer -Credential $DomCred -ScriptBlock{       
        $VMName = (Get-VM -Name VM*-01).Name
        $DomainName = "ADS-Center.de"
        $CredDomainUser = "T1-ServerTS@$DomainName"
        $CredDomainPW = ConvertTo-SecureString -String "C0mplex" -AsPlainText -Force
        $DomCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CredDomainUser, $CredDomainPW

        New-VHD -Path V:\$VMName\40GB.vhdx -SizeBytes 40GB
        Add-VMHardDiskDrive -VMName $VMName -path V:\$VMName\40GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 2


        New-VHD -Path V:\$VMName\20GB.vhdx -SizeBytes 20GB
        Add-VMHardDiskDrive -VMName $VMName -Path V:\$VMName\20GB.vhdx -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 3


        Invoke-Command -ComputerName $VMName -Credential $DomCred -ScriptBlock{
            Get-Disk | ? Size -EQ 42949672960 | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter S -UseMaximumSize | Format-Volume -FileSystem ReFS
            Get-Disk | ? Size -EQ 21474836480 | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter L -UseMaximumSize | Format-Volume -FileSystem ReFS 
        }
    }
}

Write-Host "Füller is deftig geil!!"