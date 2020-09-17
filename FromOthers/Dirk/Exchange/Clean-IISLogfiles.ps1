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