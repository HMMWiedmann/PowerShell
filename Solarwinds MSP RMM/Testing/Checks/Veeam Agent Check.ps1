$FatalErrorCount = Get-WinEvent -ProviderName "Veeam Agent" -MaxEvents $MaxEvents | Where-Object -Property Message -Like "*finished with Failed*"
$WarningRetryCount = Get-WinEvent -ProviderName "Veeam Agent" -MaxEvents $MaxEvents | Where-Object -Property Message -Like "*finished with Error and will be retried*"

if($FatalErrorCount.count -gt 1 -or $WarningRetryCount.count -gt 1)
{
    $BackupError = $true
}