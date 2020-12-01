# Windows Server
Get-WinEvent -LogName "Kaspersky Security" -MaxEvents 50 | Where-Object -Property LevelDisplayName -EQ "Warnung"


# Windows Client
Get-WinEvent -LogName "Kaspersky Endpoint Security" -MaxEvents 2 | Select-Object -Property TimeCreated -Expandproperty Message
