<#
    Patchmanagement Extensions Script fuer das Solarwinds Patchmanagement ab Agent 10.8.xx
    von Marcus von der Werth          

    Sie koennen als Befehlszeile folgende Parameter Uebergeben:
    wuoff            -Schaltet Windows Updater ab und sperrt das Programm
    wuon             -Schaltet Windows Updater wieder ein und entsperrt das Programm wieder
    wdoff            -Schaltet den Windows Defender aus 
    wdon             -Schaltet den Windows Defender wieder an
    fastbootoff      -Schaltet den Windows Fastboot aus
    wulock           -Blockiert den Windows Updater (kann zu Problemen fuehnen HRESULT - 0x8024002E)
    restartblock     -Installiert den RebootBlocker Dienst (beachten Sie die Lizenzbestimmungen unter 
                      https://www.chip.de/downloads/RebootBlocker-Windows-10-Neustart-verhindern_105909301.html)    

    Sie koennen mehrere Parameter hintereinander weg mit einen Soppelpunkt getrennt eingeben
    Beispiel:
    wuoff:wdoff:fastbootoff

Ab hier nichts mehr arndern.#>

[string]$parameters = $args[0]
[int]$argWUOn = 0
[int]$argWUOff = 0
[int]$argWDOn = 0
[int]$argWDOff = 0
[int]$argFastBoot = 0
[int]$argwulock = 0
[int]$argRebootBlock = 0


[datetime]$now = get-date
[datetime]$tomorrow = (get-date).AddDays(+1)
if($parameters.Contains(":"))
{
    [object]$argumentOBs = $parameters.Split(":")
    foreach($argumentOB in $argumentOBs)
    {
        if($argumentOB -eq "wuoff")
        {
            [int]$argWUOff = 1
        }
        if($argumentOB -eq "wulock")
        {
            [int]$argwulock = 1
        }
        if($argumentOB -eq "wuon")
        {
            [int]$argWUOn = 1
        }
        
        if($argumentOB -eq "wdoff")
        {
            [int]$argWDOff = 1
        }
        if($argumentOB -eq "wdon")
        {
            [int]$argWDOn = 1
        }
        if($argumentOB -eq "fastbootoff")
        {
            [int]$argFastBoot = 1
        }
        if($argumentOB -eq "restartblock")
        {
            [int]$argRebootBlock = 1
        }
    }
}
else
{
    if($parameters  -eq "wuoff")
    {
        [int]$argWUOff = 1
    }
    if($parameters  -eq "wuon")
    {
        [int]$argWUOn = 1
    }
    if($parameters  -eq "wdoff")
    {
        [int]$argWDOff = 1
    }
    if($parameters  -eq "wulock")
    {
        [int]$argwulock = 1
    }
    if($parameters  -eq "wdon")
    {
        [int]$argWDOn = 1
    }
    if($parameters -eq "fastbootoff")
    {
        [int]$argFastBoot = 1
    }
    if($parameters  -eq "restartblock")
    {
        [int]$argRebootBlock = 1
    }
}
[string]$global:regpathQB = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
if(Test-Path -Path $global:regpathQB -ErrorAction SilentlyContinue)
{
    [string]$keyQB = "HiberbootEnabled"
    [int]$QBStatus = (Get-ItemProperty $global:regpathQB).$keyQB
    if($QBStatus -eq 1)
    {
        if($argFastBoot -eq 1)
        {
            Set-ItemProperty -path $global:regpathQB -Name "HiberbootEnabled" -value 0 -Type DWord
        }
    }
}
[object[]]$wuaServ = get-service -Name wuauserv
[int]$wubdiwsUpdateService = ($wuaServ | Measure-Object).Count
if($wubdiwsUpdateService -eq 0)
{
    Write-Host "Warnung! Windows Update Service nicht gefunden"
    exit 1012
}

[string]$version = "Version 2.2.3"



if(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -ErrorAction SilentlyContinue)
{
    [int]$regDownloader = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")."DODownloadMode"
}
else
{
    $regDownloader = "NA"
}
if($argWUOn -eq 1 -or $argWUOff -eq 1 -or $argotherwuon -eq 1)
{
    [int]$regWUBlocked = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")."DisableWindowsUpdateAccess" 
    [int]$regWUoff = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")."NoAutoUpdate"
}
if(Test-Path -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender" -ErrorAction SilentlyContinue)
{
    $regWDOff = (Get-ItemProperty "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender")."DisableAntiSpyware"
}

[string]$strOsname = ((Get-WmiObject -ComputerName "localhost" -Class Win32_OperatingSystem -ErrorAction SilentlyContinue).Name).split("|")[0]
if($strOsname.Contains("2008") -or $strOsname.Contains("XP") -or $strOsname.Contains("Windows 7"))
{
    [bool]$gstStatus = $false
}
else
{
    [bool]$gstStatus = $true
}
if($gstStatus -eq $true)
{
    [object]$objJobs = Get-ScheduledTask | Where-Object {$_.TaskPath -eq "\Microsoft\Windows\WindowsUpdate\"}  -ErrorAction SilentlyContinue
}
[int32]$intJobcount = ($objJobs | Measure-Object).Count
Write-Host $version
Write-Host "_________________"

if($strOsname -ne "" -or $null -ne $strOsname)
{
    Write-Host "OS Name = $strOsname"
}
if($null -ne $parameters -or $parameters -ne "" -or $parameters -ne "-logfile")
{
    Write-Host "Parameter = $parameters"
}
else
{
    Write-Host "Parameter = keine Parameter angegeben"
}
if($QBStatus -ne "" -or $null -ne $QBStatus)
{
    Write-Host "Windows Fastboot = $QBStatus"
}

if($argWUOn -eq 1 -or $argWUOff -eq 1)
{
    Write-Host "Windows Updater (blocked) = $regWUBlocked"
    Write-Host "Windows Updater (on/off) = $regWUoff"
    Write-Host "Windows Updater Triggers = $intJobcount"
    if($regDownloader -ne "NA")
    {
        Write-Host "Windows Update-Uebermittlungsoptimierung = $regDownloader"
        write-host "Uebermittlungsoptimierung 0 = aus, 2 = an/LAN, 3 = an/Internet"
    }
    else
    {
        write-host "Uebermittlungsoptimierung nicht vorhanden"
    }
}


if($regWDOff -eq 1)
{
    Write-Host "Windows Defender Status = disabled"
    if($regWDOff -ne "" -and $null -ne $regWDOff)
    {
        Write-Host "Windows Defender RG Status = $regWDOff"
    }
    else
    {
        Write-Host "Windows Defender RG Status = na"
    }
}
else
{
    Write-Host "Windows Defender Status = enabled"
}



function defenderoff
{
    Write-Host "Attempting to add new value to registry keys"

    $RPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender"
    $Name = "DisableAntiSpyware"
    $Value = "1"

    if (Test-Path $RPath) {
        if(!((Get-ItemProperty -Path $RPath).$Name -eq 1))
        {    
            New-ItemProperty -Path $RPath -Name $Name -Value $Value -Property DWORD -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $RPath -Name $Name -Value $Value -ErrorAction SilentlyContinue
        }

        Write-Host "New value created successfully"
    } else {
        if(!(Test-Path -Path $RPath -ErrorAction SilentlyContinue))
        {
            New-Item -Path "HKLM:SOFTWARE\Policies\Microsoft" -Name "Windows Defender2"
            New-ItemProperty -Path $RPath -Name $Name -Value $Value -Property DWORD -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $RPath -Name $Name -Value $Value -ErrorAction SilentlyContinue
        }
        
    }
}

function defenderon
{
    Write-Host "Attempting to remove value from registry keys"

    $RPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender"
    $Name = "DisableAntiSpyware"

    if (Test-Path $RPath) {
        Remove-ItemProperty -Path $RPath -Name $Name
        Write-Host "Value removed successfully"
    } else {
        Write-Host "HKLM:SOFTWARE\Policies\Microsoft\Windows Defender does not exist"
    }
}
function rebootblocker
{
    [string]$strPath = "C:\Program Files (x86)\RebootBlocker"
    [string]$strPathExe = "C:\Program Files (x86)\RebootBlocker\RebootBlockerService.exe"
    [string]$strPathZip = $strPath + "\rebootblocker.zip"
    [string]$url = "https://www.acmeo.eu/downloads/technik/acmeo/scriptdownloads/rebootlocker/rebootlocker.zip"
    if(!(Test-Path -Path $strPath -ErrorAction SilentlyContinue))
    {
        Write-Host "Pfad "$strPath "nicht gefunden. Erstelle Pfad..."
        New-Item -Path "C:\Program Files (x86)" -Name "RebootBlocker" -ItemType Directory -Force
    }
    if(!(Test-Path -Path $strPathExe -ErrorAction SilentlyContinue))
    {
        Write-Host "Exe Pfad" $strPathExe "nicht gefunden. Teste auf ZIP..."
        if(!(Test-Path -Path $strPathZip -ErrorAction SilentlyContinue))
        {
            $shell_app=new-object -com shell.application
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url,$strPathZip) | Wait-Process 
            [string]$ziel = $strPath + "\"
            $zip_file = $shell_app.namespace($strPathZip)
            $destination = $shell_app.namespace($ziel)
            $destination.Copyhere($zip_file.items()) | Wait-Process 
        }
    }
    else
    {
        Write-Host $strPathExe "gefunden."
    }
    [object[]]$objService = Get-Service -Name RebootBlockerService -ErrorAction SilentlyContinue
    [int32]$intServiceCount = ($objService | Measure-Object).Count
    if($intServiceCount -lt 1)
    {
        New-Service -Name RebootBlockerService -DisplayName RebootBlockerService -BinaryPathName $strPathExe -Description "Verhindert den automatischen Neustart Ihres Computers nach Installation von Windows-Updates." -StartupType Automatic
        [object[]]$objService = Get-Service -Name RebootBlockerService -ErrorAction SilentlyContinue
        [int32]$intServiceCount = ($objService | Measure-Object).Count
        if($intServiceCount -lt 1)
        {
            Write-Host "Dienst RebootBlockerService nicht gefunden und Installation des Dientes fehlgeschlaghen. Abbruch..."
        }
        else
        {
            Write-Host "Dienst RebootBlockerService gefunden."
        }
    }
    else
    {
        Write-Host "Dienst RebootBlockerService gefunden."
    }
    if($objService.Status -ne "Running")
    {
        Start-Service -Name RebootBlockerService | Wait-Process
        [object[]]$objService = Get-Service -Name RebootBlockerService -ErrorAction SilentlyContinue
        if($objService.Status -ne "Running")
        {
            Write-Host "Starten des Dienstes RebootBlockerService fehlgeschlagen"
        }
        else
        {
            Write-Host "Diest RebootBlockerService arbeitet"
        }
    }
    else
    {
        Write-Host "Diest RebootBlockerService arbeitet"
    }

}

if ($argWDOn -eq 1)
{
    if($regWDOn -ne 1)
    {
        defenderon
    }

}
if ($argWDOff -eq 1)
{
    if($regWDOff -ne 1)
    {
        defenderoff
    }
}



function WindowsUpdater
{
    if(-not(Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"))
        {
            New-Item -itemType String HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate;
	    }
    if(-not(Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"))
        {
            New-Item -itemType String HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU;
	    }
    if($argotherwuon -eq 1)
    {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DisableWindowsUpdateAccess" -value 0 -Type DWord
    }
    if($argWUOff -eq 1 -and $argWUOn -eq 0)
    {
        if($argwulock -eq 1)
        {
            Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DisableWindowsUpdateAccess" -value 1 -Type DWord
        }
        else
        {
            Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DisableWindowsUpdateAccess" -value 0 -Type DWord
        }
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -value 1 -Type DWord
        if($regDownloader -ne "NA")
        {    
            Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -value 0 -Type DWord
        }
    if($gstStatus -eq $true)
    {
    [object]$objJobs = Get-ScheduledTask | Where-Object {$_.TaskPath -eq "\Microsoft\Windows\WindowsUpdate\"}  -ErrorAction SilentlyContinue
    [int32]$intJobcount = ($objJobs | Measure-Object).Count
    if($intJobcount -ge 1)
    {
    Write-Output $objJobs
    foreach($job in $objJobs)
    {
        [string]$strTaskname = $job.TaskName
        $strTaskname
        [string]$strTaskpath = $job.TaskPath
        try
        {
            Unregister-ScheduledTask -TaskName $strTaskname -TaskPath $strTaskpath -Confirm:$false
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Verbose $ErrorMessage
        }
    }
    }
    }
    }
    elseif($argWUOn -eq 1 -and $argWUOff -eq 0)
    {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DisableWindowsUpdateAccess" -value 0 -Type DWord
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -value 0 -Type DWord
        if($regDownloader -ne "NA")
        {
            Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -value 3 -Type DWord
        }
    }
}
if($argRebootBlock -eq 1)
{
    rebootblocker
}
if($argWUOff -eq 1 -or $argWUOn -eq 1)
{
    WindowsUpdater
}
else
{
    Write-Host "Windows Updater = normal"
}

exit 0