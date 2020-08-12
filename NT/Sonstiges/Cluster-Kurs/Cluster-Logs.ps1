$Clu = Get-Cluster

$Clu | select *log*

$Clu.ClusterLogLevel = 4
$Clu.ClusterLogSize = 500

Get-ClusterLog -Destination C:\Temp