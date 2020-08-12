$Action = New-ScheduledTaskAction -Execute "Certutil -crl"
$Trigger = New-ScheduledTaskTrigger -DaysInterval 2 -At 3am -Daily
$Principal = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigger -Settings $Settings
Register-ScheduledTask -TaskName "PKI-autorenewal-CRL" -InputObject $Task