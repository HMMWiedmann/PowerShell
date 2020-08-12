$Backup = Get-WBBackupSet
$Backup.Application | fl *

Start-WBApplicationRecovery -BackupSet $Backup -ApplicationInBackup $Backup.Application[0] 