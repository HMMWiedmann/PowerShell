# $DelteAfterDays = "14" #Days

#--------------------------------------------------------
#region Hilfsfunktionen
function LadeExchangeModul {
    #Prüfen welche Exchange Version. Pfad aus Umgebungsvariable
    $EXVersion = $env:ExchangeInstallPath
    #Zerlegen bei jedem "\"
    $EXVersion = $EXVersion.split("\")
    #Länge des Arrays messen und 2 abziehen (Array startet bei 0 und die Umgebungsvariable endet mit "\")
    $EXVersionlanege = $EXVersion.length - 2
    #Exchange Version ist also der Letzte-2 Array Wert.
    $EXVersion = $EXVersion[$EXVersionlanege]
    if($EXVersion -eq "V15") { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn; }
    if($EXVersion -eq "V14") { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010; }
    if($EXVersion -eq "V8") { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin; }
}

Function CleanLogFiles($TargetFolder)
{
    write-host -debug -ForegroundColor Yellow -BackgroundColor Cyan $TargetFolder

    if (Test-Path $TargetFolder) {
    #   $Files = Get-ChildItem $TargetFolder -Include *.log,*.blg, *.etl -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
        $Files = Get-ChildItem $EXLoggingPath  -Recurse `
            | Where-Object {$_.Name -like "*.log" -or $_.Name -like "*.blg" -or $_.Name -like "*.etl"} `
            | Where-Object {$_.lastWriteTime -le "$DeleteDate"} | Select-Object FullName  
        foreach ($File in $Files)
            {
            $FullFileName = $File.FullName  
            Write-Host "Deleting file $FullFileName" -ForegroundColor "yellow"; 
                Remove-Item $FullFileName -ErrorAction SilentlyContinue | out-null
            }
    }
    Else 
    {
        Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "red"
    }
}

function Test-FileLock 
{
    param (
        [parameter(Mandatory=$true)][string]$Path
    )

    $oFile = New-Object System.IO.FileInfo $Path

    if ((Test-Path -Path $Path) -eq $false) 
    {
        return $false
    }

    try {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

        if ($oStream) {
            $oStream.Close()
        }
        $false
    }
    catch {
        # file is locked by a process.
        return $true
    }
}
#endregion

try {
    Import-Module webadministration
    LadeExchangeModul

    $DeleteDate = (Get-Date).adddays(-$DelteAfterDays)

    $Websites = Get-Website
    foreach ($Website in $Websites)
    {
        $LogFilePath = $Website.LogFile.Directory

        if ((Test-FileLock -Path $LogFilePath) -eq $false) 
        {
            if ($LogFilePath -match "%SystemDrive%")  
            {
                $LogFilePath  = $LogFilePath  -replace "%SystemDrive%","C:"
            }
    
            $LogFileList = Get-ChildItem $LogFilePath -Recurse | Where-Object {! $_.PSIsContainer -and $_.lastwritetime -lt $DeleteDate} | Select-Object fullname
            foreach ($LogFile in $LogFileList)
            {
                Remove-Item $LogFile.fullname -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Host "$($LogFilePath): Datei gesperrt"
        }
    }    

    $EXLoggingPath = $env:ExchangeInstallPath + "Logging"
    $EXDiagETLPath = $env:ExchangeInstallPath + "Bin\Search\Ceres\Diagnostics\ETLTraces\"
    $EXDiagLogsPath = $env:ExchangeInstallPath + "Bin\Search\Ceres\Diagnostics\Logs"

    CleanLogFiles($EXLoggingPath)
    CleanLogFiles($EXDiagETLPath)
    CleanLogFiles($EXDiagLogsPath)
}
catch {
    Write-Host "$PSItem.Exception.Message"
}