Get-Cluster
Get-Cluster | fl *
Get-Cluster | select **

Get-ClusterGroup
Get-ClusterGroup "Cluster Group" | Get-ClusterResource
Get-ClusterGroup "Available Storage" | Get-ClusterResource
Move-ClusterGroup "Cluster Group" -Node NODE-B
Move-ClusterGroup "File-AB" -Node NODE-A

Get-SmbShare

Get-ClusterResource
Get-ClusterResource File-AB
Get-ClusterResource File-AB | Get-ClusterParameter
Get-ClusterResource File-AB | Set-ClusterParameter -Name Aliases -Value Finanz-AB