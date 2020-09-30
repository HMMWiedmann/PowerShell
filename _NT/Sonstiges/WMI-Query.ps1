Get-CimInstance -Query "SELECT Model from Win32_ComputerSystem WHERE Model LIKE %Precision Tower 7910%"
Get-CimInstance -Query "SELECT Model from Win32_ComputerSystem WHERE Model LIKE %Precision Tower 7810%"
Get-CimInstance -Query "SELECT Model from Win32_ComputerSystem WHERE Model LIKE %PowerEdge T430%"

"Precision Tower 7910"
"PowerEdge T430"
"Precision Tower 7810"