Get-Disk | sort number
Get-Disk 9 | Set-Disk -IsOffline $false
Get-Disk 9 | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -UseMaximumSize -DriveLetter T | Format-Volume -FileSystem NTFS -NewFileSystemLabel DiskT

Get-ClusterAvailableDisk
Get-ClusterResourceType

Add-ClusterGroup Notepad-AB
Add-ClusterResource -Name DiskT -Group Notepad-AB -ResourceType "Physical Disk"
Get-ClusterResource DiskT | Get-ClusterParameter
Get-ClusterResource DiskT | Set-ClusterParameter -Name "DiskIdGuid" -Value "{3259a477-23f9-4ce0-ae42-8ea7ad82e603}"
Start-ClusterResource DiskT

Add-ClusterResource -Name IP-Notepad-AB -Group Notepad-AB -ResourceType "IP Address"
Get-ClusterResource IP-Notepad-AB | Get-ClusterParameter
Get-ClusterResource IP-Notepad-AB | Set-ClusterParameter -Multiple @{"Address"="192.168.1.18";"SubnetMask"="255.255.255.0"}
Start-ClusterResource IP-Notepad-AB

Add-ClusterResource -Name NN-Notepad-AB -Group Notepad-AB -ResourceType "Network Name"
Get-ClusterResource NN-Notepad-AB | Get-ClusterParameter
Get-ClusterResource NN-Notepad-AB | Set-ClusterParameter -Name "Name" -Value "Notepad-AB"
Add-ClusterResourceDependency NN-Notepad-AB IP-Notepad-AB
Start-ClusterResource NN-Notepad-AB

Add-ClusterResource -Name AP-Notepad-AB -Group Notepad-AB -ResourceType "Generic Application"
Get-ClusterResource AP-Notepad-AB | Get-ClusterParameter
Get-ClusterResource AP-Notepad-AB | Set-ClusterParameter -Name CommandLine -Value "Notepad.exe T:\Test\Test.txt"
Get-ClusterResource AP-Notepad-AB | Set-ClusterParameter -Name Currentdirectory -Value "C:\Windows\System32"
Add-ClusterResourceDependency AP-Notepad-AB NN-Notepad-AB
Add-ClusterResourceDependency AP-Notepad-AB DiskT
Start-ClusterResource AP-Notepad-AB