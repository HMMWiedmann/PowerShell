$hv = Get-ADComputer -Filter { dnshostname -like "*hyperv*" } | Where-Object dnshostname -NotLike "*15*"

$hv.dnshostname

Stop-Computer -ComputerName $hv.dnshostname -Force