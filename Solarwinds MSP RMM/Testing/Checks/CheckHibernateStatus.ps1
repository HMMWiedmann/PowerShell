$SettingStatus = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power -name HibernateEnabled
$FileStatus = Get-CimInstance -Query "Associators of {Win32_Directory.Name='C:\'} Where ResultClass=CIM_DataFile" | Where-Object {$PSItem.name -match 'hiberfil.sys'}

if ($SettingStatus.HibernateEnabled -eq 1 -and $null -ne $FileStatus) {
    powercfg.exe /h off
}