# '==================================================================================================================================================================
# 'Script to Cleanup and Uninstall PME
#'
# 'Disclaimer
# 'The sample scripts are not supported under any SolarWinds support program or service.
# 'The sample scripts are provided AS IS without warranty of any kind.
# 'SolarWinds further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose.
# 'The entire risk arising out of the use or performance of the sample scripts and documentation stays with you.
# 'In no event shall SolarWinds or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever
# '(including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss)
# 'arising out of the use of or inability to use the sample scripts or documentation.
# '==================================================================================================================================================================
 
#Determines whether the OS is 32 or 64 bit

Param(
	[string]$forceRemove = "n"
)

$AgentLocationGP = "\Advanced Monitoring Agent GP\"
$AgentLocation = "\Advanced Monitoring Agent\"

function getAgentPath {

	$Keys = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
	$Items = $Keys | Foreach-Object {Get-ItemProperty $_.PsPath }
	ForEach ($Item in $Items) {
		if ($Item.DisplayName -like "Advanced Monitoring Agent" -or $Item.DisplayName -like "Advanced Monitoring Agent GP"){
			$script:LocalFolder = $Item.InstallLocation
			break
		}
	}

	$Keys = Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
	$Items = $Keys | Foreach-Object {Get-ItemProperty $_.PsPath }
	ForEach ($Item in $Items) {
		if ($Item.DisplayName -like "Advanced Monitoring Agent" -or $Item.DisplayName -like "Advanced Monitoring Agent GP"){
			$script:LocalFolder = $Item.InstallLocation
			break
		}
	}

	if(!$script:LocalFolder) {
		write-host "Agent Path not found. Exiting..."
		exit 1001
	}

	if(($script:LocalFolder -match '.+?\\$') -eq $false) {
		$script:LocalFolder = $script:LocalFolder + "\"
	}

	if(!(test-path $script:LocalFolder)) {
		write-host "The Agent Registry Entry is pointing to a path that doesn't exist. Falling back to legacy method of checking agent location."
		getAgentPath_Legacy
	}

	write-host "Agent Path is: " $script:LocalFolder
}

function getAgentPath_Legacy {

	If((Get-WmiObject Win32_OperatingSystem).OSArchitecture -like "*64*"){

	#Check Agent Install Location
	$PathTesterGP = "C:\Program Files (x86)" +  $AgentLocationGP + "\winagent.exe"
	$PathTester = "C:\Program Files (x86)" +  $AgentLocation + "\winagent.exe"
		
		If(Test-Path $PathTesterGP){
			$script:LocalFolder = "C:\Program Files (x86)" +  $AgentLocationGP
		}
		Elseif(Test-Path $PathTester) {
			$script:LocalFolder = "C:\Program Files (x86)" +  $AgentLocation
		} else {
			write-host "Agent Path not found. Exiting..."
			exit 1001
		}
	}

	Else {

	$PathTesterGP = "C:\Program Files" +  $AgentLocationGP + "\winagent.exe"
	$PathTester = "C:\Program Files" +  $AgentLocation + "\winagent.exe"
		
		If(Test-Path $PathTesterGP){
			$script:LocalFolder = "C:\Program Files" +  $AgentLocationGP
		}
		Elseif(Test-Path $PathTester) {
			$script:LocalFolder = "C:\Program Files" +  $AgentLocation
		} else {
			write-host "Agent Path not found. Exiting..."
			exit 1001
		}
		
	}

}

function isPMEActive {
	#Gets the content of the Settings file
	[string]$filecontents = Get-Content ($script:LocalFolder + "settings.ini")
	#If the file contains the Patch settings already...
	If($filecontents -match "\[PATCHMANAGEMENT\][^\[\]]*ACTIVATED=1") {
		if($script:forceRemove.ToLower() -eq "y") {
			write-host "Patch Management is still active on the Dashboard. However you have opted to force remove. Proceeding with cleanup..."
		} else {
			write-host "Patch Management is still active on the Dashboard. Run this script after Patch Management has been disabled on the dashboard."
			exit 1001
		}
	} else {
		write-host "Patch Management is not active on the Dashboard. Proceeding with cleanup..."
	}
}

function runPMEUninstaller {

	$hash = @{"$($script:LocalFolder)patchman\unins000.exe" = "https://s3.amazonaws.com/new-swmsp-net-supportfiles/PermanentFiles/PMECleanup_Repository/patchmanunins000.dat";
				"$($script:LocalFolder)CacheService\unins000.exe" = "https://s3.amazonaws.com/new-swmsp-net-supportfiles/PermanentFiles/PMECleanup_Repository/cacheunins000.dat";
				"$($script:LocalFolder)RpcServer\unins000.exe" = "https://s3.amazonaws.com/new-swmsp-net-supportfiles/PermanentFiles/PMECleanup_Repository/rpcunins000.dat"}
	foreach ($key in $hash.Keys) {
		if (Test-Path $key) {
			$datItem = $key
			$datItem = $datItem -replace "exe","dat"

			if (!(Test-Path $datItem)) {
				write-host "Dat file required to run uninstaller doesn't exist. Attempting download..."
				downloadFileToLocation $hash[$key] $datItem 
				if(!(Test-Path $datItem)) {
					write-host "Unable to download dat file for uninstaller to run. PME must be removed manually. Exiting..."
					exit 1001
				}
			}
			write-host "$key Uninstaller exists - Running Uninstaller..."
			$pinfo = New-Object System.Diagnostics.ProcessStartInfo
			$pinfo.FileName = $key
			$pinfo.RedirectStandardError = $true
			$pinfo.RedirectStandardOutput = $true
			$pinfo.UseShellExecute = $false
			$pinfo.Arguments = "/silent"
			$p = New-Object System.Diagnostics.Process
			$p.StartInfo = $pinfo
			$p.Start() | Out-Null
			$p.WaitForExit()
			$script:ExitCode = $p.ExitCode
			write-host "The Exit Code is:" $script:ExitCode
			start-sleep -s 5
		}
		else {
			write-host "$key Uninstaller doesn't exist - moving on..."	
		}
	}
}

function downloadFileToLocation ($URL, $Location) {
	$wc = New-Object System.Net.WebClient
	try {
		$wc.DownloadFile($URL, $Location)
	} catch {
		write-host "Exception when downloading file $Location from source $URL."
	}
	
}

function removePMEFoldersAndKeys {
	$array = @()
	$array += "C:\ProgramData\SolarWinds MSP\PME"
	$array += "C:\ProgramData\SolarWinds MSP\SolarWinds.MSP.CacheService"
	$array += "C:\ProgramData\SolarWinds MSP\SolarWinds.MSP.Diagnostics"
	$array += "C:\ProgramData\SolarWinds MSP\SolarWinds.MSP.RpcServerService"
	$array += "$($script:LocalFolder)patchman"
	$array += "$($script:LocalFolder)CacheService"
	$array += "$($script:LocalFolder)RpcServer"
	if ((test-path "hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall") -eq $true){
	$recurse = get-childitem -path "hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	foreach ($entry in $recurse) {
		foreach ($key in get-itemproperty -path "Registry::$entry") {
			if($key.DisplayName -eq "SolarWinds MSP RPC Server" -or $key.DisplayName -eq "SolarWinds MSP Patch Management Engine" -or $key.DisplayName -eq "SolarWinds MSP Cache Service") {
				$temp = $entry.name -replace "HKEY_LOCAL_MACHINE", "HKLM:"
				$array += $temp
			}
		}
	}
	}
	$recurse = get-childitem -path "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	foreach ($entry in $recurse) {
		foreach ($key in get-itemproperty -path "Registry::$entry") {
			if($key.DisplayName -eq "SolarWinds MSP RPC Server" -or $key.DisplayName -eq "SolarWinds MSP Patch Management Engine" -or $key.DisplayName -eq "SolarWinds MSP Cache Service") {
				$temp = $entry.name -replace "HKEY_LOCAL_MACHINE", "HKLM:"
				$array += $temp
			}
		}
	}
	foreach ($FolderLocation in $Array) {
		if (Test-Path $FolderLocation) {
			write-host "$FolderLocation exists. Removing item..."
			try {
				remove-item $folderLocation -recurse -force
			}
			catch  {
				Write-Host "The item $FolderLocation exists but cannot be removed automatically. Please remove manually."
				$removalError = $error[0]
				Write-Host "Exception from removal attempt is: $removalError" 
			}
		} else {
			write-host "$FolderLocation doesn't exist - moving on..."
		}
	}
}

function removePMEServices {
$array = @()
$array += "SolarWinds.MSP.CacheService"
$array += "SolarWinds.MSP.RpcServerService"
$array += "SolarWinds.MSP.CacheService"
foreach ($serviceName in $array) {
	If (Get-Service $serviceName -ErrorAction SilentlyContinue) {
	write-host "$serviceName service exists. Removing service..."
    try {
	Stop-service -Name $serviceName 
	sc.exe delete $serviceName
	} catch {
		"The service cannot be removed automatically. Please remove manually."
		$removalError = $error[0]
		Write-Host "Exception from removal attempt is: $removalError" 
	}

	} Else {

		Write-Host "$serviceName service not found."

	}
}
}
getAgentPath
isPMEActive
runPMEUninstaller
removePMEServices
removePMEFoldersAndKeys