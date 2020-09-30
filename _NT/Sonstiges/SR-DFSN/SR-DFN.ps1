$SRNode1 = "VCCSTRE-01"
$SRNode2 = "VCCSTRE-02"

$RG1 = "RG-STRE0102"
$RG2 = "RG-STRE0201"

$DFSNFolderTargetPath = "\\MAIL.CLUSTER-CENTER.DE\STRE-01\STRE-Share"
$Targetpath1 = "\\VCCSTRE-01.MAIL.CLUSTER-CENTER.DE\D$"
$Targetpath2 = "\\VCCSTRE-02.MAIL.CLUSTER-CENTER.DE\D$"

# Set new SR
New-SRPartnership -SourceComputerName $SRNode1 -SourceRGName $RG1 -SourceVolumeName D: -SourceLogVolumeName L: -DestinationComputerName $SRNode2 -DestinationRGName $RG2 -DestinationVolumeName D: -DestinationLogVolumeName L: -ReplicationMode Asynchronous

# SR: 1 to 2
Set-SRPartnership -NewSourceComputerName $SRNode1 -SourceRGName $RG1 -DestinationComputerName $SRNode2 -DestinationRGName $RG1

# SR: 2 to 1
Set-SRPartnership -NewSourceComputerName $SRNode2 -SourceRGName $RG2 -DestinationComputerName $SRNode1 -DestinationRGName $RG2

# Remove SR
Get-SRPartnership | Remove-SRPartnership -Force
Invoke-Command -ComputerName ($SRNode1,$SRNode2) -ScriptBlock{ Get-SRGroup | Remove-SRGroup -Force }

# DFS Namespace
get-DfsnFolderTarget -Path $DFSNFolderTargetPath | fl *
Set-DfsnFolderTarget -Path $DFSNFolderTargetPath -TargetPath $Targetpath1 -State Offline

# Change Direction SR and DFSN
# 1 to 2
Set-SRPartnership -NewSourceComputerName $SRNode1 -SourceRGName $RG1 -DestinationComputerName $SRNode2 -DestinationRGName $RG2 -Force
Set-DfsnFolderTarget -Path $DFSNFolderTargetPath -TargetPath $Targetpath1 -State Online
Set-DfsnFolderTarget -Path $DFSNFolderTargetPath -TargetPath $Targetpath2 -State Offline

# 2 to 1
Set-SRPartnership -NewSourceComputerName $SRNode2 -SourceRGName $RG2 -DestinationComputerName $SRNode1 -DestinationRGName $RG1 -Force
Set-DfsnFolderTarget -Path $DFSNFolderTargetPath -TargetPath $Targetpath2 -State Online
Set-DfsnFolderTarget -Path $DFSNFolderTargetPath -TargetPath $Targetpath1 -State Offline