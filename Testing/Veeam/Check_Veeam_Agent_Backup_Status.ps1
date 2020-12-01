# Quelle: https://helpcenter.veeam.com/docs/agentforwindows/userguide/backup_cmd.html?ver=40

$VeeamBackupStatus = cmd.exe /c "echo %ERRORLEVEL%" 

switch ($VeeamBackupStatus) 
{
    "0" { Write-Host "backup successfully created" }
    "-1" { 
        Write-Host "backup job failed to start or completed with error `n `n"
        Write-Host "Warnungen gefunden:"
        Get-WinEvent -LogName "Veeam Agent" -MaxEvents 100 | Where-Object -Property LevelDisplayName -EQ "Warnung" | Select-Object -Property TimeCreated,Message | Format-List -Property *
        Get-WinEvent -LogName "Veeam Agent" -MaxEvents 100 | Where-Object -Property LevelDisplayName -EQ "Warning" | Select-Object -Property TimeCreated,Message | Format-List -Property *
        Write-Host "Fehler gefunden:"
        Get-WinEvent -LogName "Veeam Agent" -MaxEvents 100 | Where-Object -Property LevelDisplayName -EQ "Fehler" | Select-Object -Property TimeCreated,Message | Format-List -Property *
    }
    "5" { Write-Host "backup job is currently running and cannot be started from the command line interface" }
    Default { Write-Host "Could not find the returned Value"}
}