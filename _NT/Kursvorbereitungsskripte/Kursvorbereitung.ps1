powercfg.exe /change monitor-timeout-ac 0
powercfg.exe /change monitor-timeout-dc 0
powercfg.exe /change standby-timeout-dc 0
powercfg.exe /change standby-timeout-ac 0
powercfg.exe /change hibernate-timeout-ac 0
powercfg.exe /change hibernate-timeout-dc 0

Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" –Value 0 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" 

Set-NetFirewallProfile -All -Enabled False

Winrm quickconfig -quiet -Force