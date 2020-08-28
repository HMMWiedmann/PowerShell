<#  
    Name:
    Disable_Windows10_Fastboot
    
    Beschreibung: 
    Überprüft den Status von Windows 10 Fastboot und deaktiviert ihn gegebenenfalls

    Nutzungshinweise:
#> 
try {
    $SettingStatus = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power -name HibernateEnabled
    $FileStatus = Get-CimInstance -Query "Associators of {Win32_Directory.Name='C:\'} Where ResultClass=CIM_DataFile" | Where-Object {$PSItem.name -match 'hiberfil.sys'}

    if ($SettingStatus.HibernateEnabled -eq 1 -and $null -ne $FileStatus) {
        Write-Host "Windows Fastboot ist aktiviert."
        powercfg.exe /h off
        Exit 1001
    }
    else 
    {
        Write-Host "Windows Fastboot ist deaktivert."
        Exit 0 
    }
}
catch {
    Write-Host "Etwas ist schief gelaufen!"
    Exit 0
}
