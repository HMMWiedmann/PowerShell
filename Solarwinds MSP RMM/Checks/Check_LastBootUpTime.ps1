$MaxDaysRunning = $args[0]

$Time = Get-WmiObject win32_operatingsystem | Select-Object @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
$DaysRunning = ((Get-Date) - ($Time).LastBootUpTime).Days

if ($DaysRunning -gt $MaxDaysRunning) 
{
    Write-Host "LastBooUptime: $($time.LastBootUpTime | Get-Date -Format "dd/MM/yyyy hh:mm:ss")"
    Exit 1001
}
else {
    Write-Host "LastBooUptime: $($time.LastBootUpTime | Get-Date -Format "dd/MM/yyyy hh:mm:ss")"
    Exit 0
}