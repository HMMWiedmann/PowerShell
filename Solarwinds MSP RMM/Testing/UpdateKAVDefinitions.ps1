# Windows Server 10.x
$Caption = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
if ($Caption -like "Microsoft Windows Server*") 
{
    Set-Location "${env:ProgramFiles(x86)}\Kaspersky Lab\Kaspersky Security for Windows Server"
    .\kavshell.exe UPDATE /AK
    $run++
}

# Windows Client 
$Caption = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
if ($Caption -like "Microsoft Windows 10*") 
{
    Set-Location "${env:ProgramFiles(x86)}\Kaspersky Lab\Kaspersky Endpoint Security for Windows"
    .\avp.com update
    $run++
}

if ($run -lt $null) 
{
    Write-Host "Es wurde kein Update der Definitionen gestartet!"
    Exit 1001
}
else 
{
    Exit 0
}