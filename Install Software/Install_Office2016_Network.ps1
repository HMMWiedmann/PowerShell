# $SharePath = "\\win10-2004-01\Office2016"
$PSDriveName = "OfficeInstall"
# $AdminFilePath = ".\offic2016.MSP"

try {
    Write-Host "Mounting Networkshare $SharePath"
    New-PSDrive -Name $PSDriveName -PSProvider FileSystem -Root $SharePath | Out-Null

    Write-Host "Starting Installation of Office"
    Set-Location -Path "$($PSDriveName):"
    .\setup.exe /adminfile $AdminFilePath
    $InstallProcess = Get-Process -Name Setup* | Where-Object -Property ProductVersion -Like "16.0*"

    while($null -ne $InstallProcess)
    {
        "Installation in progress"
        Start-Sleep -Seconds 5
        $InstallProcess = Get-Process -Name Setup* | Where-Object -Property ProductVersion -Like "16.0*"
    }

    Write-Host "Installation is finished"
}
catch {
    Write-Host $PSItem.Exception.Message -ForegroundColor Red
}
finally
{
    Set-Location -Path "$($env:SystemDrive)\"
    Write-Host "Removing Networkshare $SharePath"
    Remove-PSDrive -Name $PSDriveName
}