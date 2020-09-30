function Enable-RemoteDesktop
{
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}