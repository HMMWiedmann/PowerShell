$Clu = Get-Cluster 
$Clu.BlockCacheSize = 4096
Get-Cluster | select Block*

Get-ClusterSharedVolume -Name "Cluster Virtual Disk (Disk-S)" | Get-ClusterParameter