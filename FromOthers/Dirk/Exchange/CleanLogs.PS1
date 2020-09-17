<#

www.FrankysWeb.de

Script zum Bereinigen von IIS Logfiles
by Frank Zoechling
-
Um das Script als Task auszufuehren, kann eine Aufgabe angelegt werden. die das Script startet:
powershell.exe c:\scripts\Clean-IISLogfiles.ps1  -noprofile �Noninteractive

#>


$deleteafterdays = "7" #Days

#--------------------------------------------------------
import-module webadministration
$deletedate = (get-date).adddays(-$deleteafterdays)

$websites = get-website
foreach ($website in $websites)
{
$logfiledir = $website.logfile.directory
if ($LogFiledir -match "%SystemDrive%")  
  {
  $logfiledir  = $logfiledir  -replace "%SystemDrive%","c:"
  }

$logfilelist = Get-ChildItem $logfiledir -Recurse | Where-Object {! $_.PSIsContainer -and $_.lastwritetime -lt $deletedate} | Select-Object fullname
  foreach ($logfile in $logfilelist)
   {
    remove-item $logfile.fullname
   }
}

Set-Executionpolicy RemoteSigned
$days=0
$IISLogPath="C:\inetpub\logs\LogFiles\"
$ExchangeLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Logging\"
$ETLLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\"
$ETLLoggingPath2="C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs"
Function CleanLogfiles($TargetFolder)
{
  write-host -debug -ForegroundColor Yellow -BackgroundColor Cyan $TargetFolder

    if (Test-Path $TargetFolder) {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$days)
    #   $Files = Get-ChildItem $TargetFolder -Include *.log,*.blg, *.etl -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
        $Files = Get-ChildItem "C:\Program Files\Microsoft\Exchange Server\V15\Logging\"  -Recurse | Where-Object {$_.Name -like "*.log" -or $_.Name -like "*.blg" -or $_.Name -like "*.etl"}  | Where-Object {$_.lastWriteTime -le "$lastwrite"} | Select-Object FullName  
        foreach ($File in $Files)
            {
               $FullFileName = $File.FullName  
               Write-Host "Deleting file $FullFileName" -ForegroundColor "yellow"; 
                Remove-Item $FullFileName -ErrorAction SilentlyContinue | out-null
            }
       }
Else {
    Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "red"
    }
}
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanLogfiles($ETLLoggingPath)
CleanLogfiles($ETLLoggingPath2)