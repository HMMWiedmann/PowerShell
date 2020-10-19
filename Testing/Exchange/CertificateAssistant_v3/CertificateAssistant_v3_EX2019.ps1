#requires -version 5.0
#------------------------------------------------------------------------------------------------
# Please edit the following settings:
#------------------------------------------------------------------------------------------------

# You can use the Let's Encyrpt Stage (LE_Stage, for testing) or the Let's Encrypt
# production environment. Please first test this script with the LE Stage System. 
# If it's working fine, switch it to LE Production (LE_Prod):

# $LetsEncryptMode = "LE_Stage"

# If you are running Let's Encrypt ACME Sharp Module at the first time,
# you may have no Let's Encrypt registration. Let's Encrypt needs an 
# E-Mail Address for registration. This script will create a registration
# if no active registration were found:

# $ContactMail = "yourcontact@yourdomain.tld"

# This script will export the Let's Encrypt certificate and save it to
# the directory where this Script is started from. You have to set a
# password for the exported certificate:

# $PFXPasswort = "YourPassword"

# Per Default this Script will create a logfile with debug informations
# in the directory where script is started from. It also logs to the
# console window. If you don't want to see what's going on, you could
# change this parameter to $false:

# $WriteConsoleLog = $true

# If you don't want to let the script automaticaly determine the Exchange
# Server FQDNs, you can disable this feature and set your own values.
# You have to set $DetermineExchangeFQDNs to $false and specify your own
# DNS Names.

# $DetermineExchangeFQDNs = $true

# If you have set $DetermineExchangeFQDNs to $false, you have to specify
# your own FQDNs here. The first FQDN in the list will be used as 
# Common Name (CN). Leave this setting as is it, if you have set 
# $DetermineExchangeFQDNs = $true:

# $CustomFQDNs = @("servername.domain.tld","server2.domain.tld")

# If you want to get an E-Mail with the logfile attached, you can configure
# Mail settings here:

$SendMail = $false
$SmtpServer = "YourSMTPServer"
$From = "YourSenderEMailAddress@domain.tld"
$To = "YourRecipient@domain.tld"
$Subject = "Certificate Assistant Logfile"
$Body = "This E-Mail was sent by Certificate Assistant, you will find the logfile attached."
$SMTPAuth = $false
$SMTPUser = "username"
$SMTPPassword = "password"

# That's all. Please make sure that your Exchange Server is accessible on
# Port 80 (http) and Port 443 (https) from the Internet. Otherwise the
# Let's Encrypt validation will fail.
# Please keep in mind, that you can't request a certificate with
# non-routable domain names (domain.local, domain.intern, etc). This script
# only supports HTTP01 validation, so you can't request Wildcard certificates from LE
# (of course you can request SAN certificates from LE)
#
# Here you will find an article about this script (sorry, german language):
#
# https://www.frankysweb.de/exchange-certificate-assistant-neue-version
#------------------------------------------------------------------------------------------------

#Set the Logfile
[string]$LogName = $PSScriptRoot + "\ACMELOG_" + (get-date -Format "ddMMyyyy") + ".log"
#[string]$LogName = "C:\Test" + "\ACMELOG_" + (get-date -Format "ddMMyyyy") + ".log"

#Function Write-ACMELog
#This is a helper function for troubleshooting / logging
function Write-ACMELog ($ScriptSection, $EventType, $Message, $ErrorDetails) {
 #Create a Logfile name (ScriptRunPath + ACMELOG + Date)
 $CheckLog = Test-Path $LogName
 $TimeStamp = get-date -Format "dd.MM.yyyy HH:mm:ss"
 if ($CheckLog)
  {
   #If logfile exists, add a message
   if ($ErrorDetails -match ";") {$ErrorDetails = $ErrorDetails.replace(";","")}
   "$TimeStamp" + ";" + "$ScriptSection" + ";" + "$EventType" + ";" + "$Message" + ";" + "$ErrorDetails" | add-content $logname
   if ($WriteConsoleLog -eq $true) {write-host "$TimeStamp" - "$ScriptSection" - "$EventType" - "$Message"}
  }
  else
  {
   #if no logfile exists, create a log and add message
   if ($ErrorDetails -match ";") {$ErrorDetails = $ErrorDetails.replace(";","")}
   "TimeStamp;ScriptSection;Type;Message;ErrorDetails" | set-content $LogName
   "$TimeStamp" + ";" + "$ScriptSection" + ";" + "$EventType" + ";" + "$Message" + ";" + "$ErrorDetails" | add-content $logname
   if ($WriteConsoleLog -eq $true) {write-host "$TimeStamp" - "$ScriptSection" - "$EventType" - "$Message"}
  }
}

#System parameters to logfile (troubleshooting only)
Write-ACMELog "System" "Info" "Geting system parameters"
try
 {
  [string]$PowerShellVersion = (get-host).version
  $OperatingSystemVersion = [environment]::OSVersion.Version
  [string]$OperatingSystemVersionString = $OperatingSystemVersion
  Write-ACMELog "System" "Info" "Certificate Assistant Exchange 2019 Version"
  Write-ACMELog "System" "Info" "PowerShell Version: $PowerShellVersion OSVersion: $OperatingSystemVersionString"
 }
catch
 {
  Write-ACMELog "System" "Error" "Failed to get PowerShell and OS Version"
 }

#Check if ACME Module installed
Write-ACMELog "Check Posh-ACME" "Info" "Check if Module installed"
$CheckACMEModule = Get-Module Posh-ACME -ListAvailable | where {$_.version.major -ge 3 -and $_.version.minor -ge 11}

#If Module isn't installed, try to install it
if (!$CheckACMEModule)
 {
  Write-ACMELog "Check Posh-ACME" "Warning" "Posh-ACME not installed, try to install it"
  
  if ($OperatingSystemVersion.Major -ge 10)
  {
   Write-ACMELog "Check Posh-ACME" "Info" "Using Windows Server 2016 installation method"
   try
   {
    #Try to install the ACMESharp Module
	$nuget = Install-PackageProvider -Name NuGet -Force -confirm:$false
    $poshacme = Install-Module -Name Posh-ACME -force -confirm:$false
    Write-ACMELog "Check Posh-ACME" "Info" "Installation successfull"
   }
   catch
   {
    #If Installation failed, return false as error
    $ErrorDetails = $_.Exception.Message
    Write-ACMELog "Check Posh-ACME" "Error" "Installation failed or arborted" "$ErrorDetails"
   }
  }
  else
  {
   Write-ACMELog "Check Posh-ACME" "Info" "Using legacy installation method"
   try
   {
    #Try to download the Package Management Module
    $PMFile = "$PSScriptRoot" + "\poshacme.zip"
    Write-ACMELog "Check Posh-ACME" "Info" "Try to download PackageManagement-MSI Path: $pmfile"
    $DownloadPM = Invoke-WebRequest -Uri "https://github.com/rmbolger/Posh-ACME/archive/master.zip" -OutFile $PMFile
    #Try to Install Posh ACME
    $ExpandFile = Expand-Archive $PMFile -DestinationPath $PSScriptRoot

    Write-ACMELog "Check Posh-ACME" "Info" "Installation successfull"
   }
   catch
   {
    #If Installation failed, return false as error
    $ErrorDetails = $_.Exception.Message
    Write-ACMELog "Check Posh-ACME" "Error" "Installation failed or arborted" "$ErrorDetails"
   }
  }
 }

#Load ACME Modules
Write-ACMELog "Load Posh-ACME" "Info" "Posh-ACME is installed, try to load it"
try 
 {
  $CheckACMEModule = Get-Module Posh-ACME -ListAvailable | where {$_.version.major -ge 3 -and $_.version.minor -ge 11}
  #Try to load the ACMESharp Module
  if ($CheckACMEModule) {
   Import-Module Posh-ACME
  }
  else {
  	Import-Module $PSScriptRoot\Posh-ACME-master\Posh-ACME\Posh-ACME.psm1
  }
  if ((Get-Command -Module Posh-ACME).count -gt 1)
   {
    [string]$ACMEVersion = (get-Module Posh-ACME).version
    Write-ACMELog "Load Posh-ACME" "Info" "Module Import was successfull, PoshACMEVersion $ACMEVersion"
   }
 }
catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Load Posh-ACME" "Error" "Posh-ACME is installed, but can't load it" "$ErrorDetails"
  exit
 }

#Load Exchange Modules
Write-ACMELog "Load Exchange SnapIns" "Info" "Try to load Exchange SnapIns"
Add-PSSnapin *exchange* -ea 0
$CheckExchangeSnapin = Get-PSSnapin *exchange* -ea 0
if ($CheckExchangeSnapin)
 {
  Write-ACMELog "Load Exchange SnapIns" "Info" "Sucessfully loaded Exchange SnapIns"
 } else {
  Write-ACMELog "Load Exchange SnapIns" "Error" "Failed to load Exchange SnapIns, exiting script"
  exit
 }
 
#Creating .Well-Known Directory in IIS
Write-ACMELog "IIS" "Info" "Trying to create .Well-Known Directory"
try {
 $WebsitePath = (Get-Website "Default Web Site").PhysicalPath
 if ($WebsitePath -match "%SystemDrive%") {$WebsitePath = $WebsitePath.replace("%SystemDrive%","c:")}
 $WellKnownFolder = $WebsitePath + "\Well-Known"
 $AcmeFolder = $WellKnownFolder + "\acme-challenge"
 if (test-path $WellKnownFolder) {
  Write-ACMELog "IIS" "Info" "Well-Known Folder already exists, skipping"
  try {
  $IISMimeType = Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent" -Name "." -Value @{ fileExtension='.'; mimeType='text/plain' }
  Write-ACMELog "IIS" "Info" "Added Mime Type to Well-Known Folder"
  }
  catch {
   Write-ACMELog "IIS" "Warning" "Mime Type was not added to Well-Known folder, maybe it was already added"
  }
 }
 else {
 $CreateWellKnownFolder = New-Item -Path $WebsitePath -Name "Well-Known" -ItemType "directory"
 $CreateAcmeFolder = New-Item -Path $WellKnownFolder -Name "acme-challenge" -ItemType "directory"
 $IISvDir = Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/site[@name='Default Web Site']/application[@path='/']" -name "." -value @{path='/.well-known';physicalPath=$WellKnownFolder}
 start-sleep -seconds 3
 try {
  $IISMimeType = Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent" -Name "." -Value @{ fileExtension='.'; mimeType='text/plain' }
  Write-ACMELog "IIS" "Info" "Added Mime Type to Well-Known Folder"
  }
  catch {
   Write-ACMELog "IIS" "Warning" "Mime Type was not added to Well-Known folder, maybe it was already added"
  }
 Write-ACMELog "IIS" "Info" "Successfully created .Well-Known Directory"
 }
}
catch {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "IIS" "Info" "Error Creating and enabling Well-Known Folder: $ErrorDetails"
}

#Change Let's Encrypt IIS Directory to http for validating
Write-ACMELog "IIS" "Info" "Changing Let's Encrypt IIS directory to http"
try
 {
  $IISDir = Set-WebConfigurationProperty -Location "Default Web Site/.well-known" -Filter 'system.webserver/security/access' -name "sslFlags" -Value None
  Write-ACMELog "IIS" "Info" "Successfully changed Let's Encrypt IIS directory to http"
 }
catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "IIS" "Error" "Failed to change Let's Encrypt IIS directory to http" "$ErrorDetails"
 }

#Verify Let's Encrypt SSL Settings
Write-ACMELog "IIS" "Info" "Checking Let's Encrypt IIS directory to accept validation by http request"
$IISDirCeck = (Get-WebConfigurationProperty -Location "Default Web Site/.well-known" -Filter 'system.webserver/security/access' -name "sslFlags").Value
if ($IISDirCeck -match 0)
 {
  Write-ACMELog "IIS" "Info" ".well-known directory accepts http"
 }
else
 {
  Write-ACMELog "IIS" "Error" ".well-known directory dosen't accepts http"
  exit
 }
 
#Getting Exchange FQDNs from configured URLs
if ($DetermineExchangeFQDNs -eq $true)
{
 Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange FQDNs"
 #Local Server Name
 try
  {
   Write-ACMELog "Exchange FQDNs" "Info" "Getting local Exchange Server Name"
   $ExchangeServer = (Get-ExchangeServer $env:computername).Name
   Write-ACMELog "Exchange FQDNs" "Info" "Local Exchange Name $ExchangeServer"
  }
 catch
  {
   $ErrorDetails = $_.Exception.Message
   Write-ACMELog "Exchange FQDNs" "Error" "Error Getting local Exchange Server Name" "$ErrorDetails"
  }

 #Autodiscover
 try
  {
   Write-ACMELog "Exchange FQDNs" "Info" "Getting Autodiscover Hostname"
   $AutodiscoverFQDN = ((Get-ClientAccessService -Identity $ExchangeServer).AutoDiscoverServiceInternalUri.Host).ToLower()
   [array]$CertNames += $AutodiscoverFQDN 
   Write-ACMELog "Exchange FQDNs" "Info" "Autodiscover Hostname $AutodiscoverFQDN"
  }
 catch
  {
   Write-ACMELog "Exchange FQDNs" "Error" "Error geting Autodiscover FQDN" "$ErrorDetails"
  }

 #Outlook Anywhere
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange Outlook Anywhere External FQDN"
  $OAExtFQDN = ((Get-OutlookAnywhere -Server $ExchangeServer).ExternalHostname.Hostnamestring).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange Outlook Anywhere External FQDN $OAExtFQDN"
  [array]$CertNames += $OAExtFQDN
 
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange Outlook Anywhere Internal FQDN"
  $OAIntFQDN = ((Get-OutlookAnywhere -Server $ExchangeServer).Internalhostname.Hostnamestring).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange Outlook Anywhere Internal FQDN $OAExtFQDN"
  [array]$CertNames += $OAIntFQDN
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange Outlook Anywhere FQDNs" "$ErrorDetails"
 }

 #OAB
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange OAB External FQDN"
  $OABExtFQDN = ((Get-OabVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange OAB External FQDN $OABExtFQDN"
  [array]$CertNames += $OABExtFQDN

  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange OAB Internal FQDN"
  $OABIntFQDN = ((Get-OabVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange OAB Internal FQDN $OABIntFQDN"
  [array]$CertNames += $OABIntFQDN 
 }
 catch
 {
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange OAB FQDNs" "$ErrorDetails"
 }

 #ActiveSync
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange EAS Internal FQDN"
  $EASIntFQDN = ((Get-ActiveSyncVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange EAS Internal FQDN $EASIntFQDN"
  [array]$CertNames += $EASIntFQDN

  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange EAS External FQDN"
  $EASExtFQDN = ((Get-ActiveSyncVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange EAS External FQDN $EASExtFQDN"
  [array]$CertNames += $EASExtFQDN
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange EAS FQDNs" "$ErrorDetails"
 }

 #EWS
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange EWS Internal FQDN"
  $EWSIntFQDN = ((Get-WebServicesVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange EWS Internal FQDN $EWSIntFQDN"
  [array]$CertNames += $EWSIntFQDN

  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange EWS External FQDN"
  $EWSExtFQDN = ((Get-WebServicesVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange EWS External FQDN $EWSExtFQDN"
  [array]$CertNames += $EWSExtFQDN
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange EWS FQDNs" "$ErrorDetails"
 }

 #ECP
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange ECP Internal FQDN"
  $ECPIntFQDN = ((Get-EcpVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange EWS Internal FQDN $ECPIntFQDN"
  [array]$CertNames += $ECPIntFQDN

  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange ECP External FQDN"
  $ECPExtFQDN = ((Get-EcpVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange ECP External FQDN $ECPExtFQDN"
  [array]$CertNames += $ECPExtFQDN
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange ECP FQDNs" "$ErrorDetails"
 }

 #OWA
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange OWA Internal FQDN"
  $OWAIntFQDN =  ((Get-OwaVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange OWA Internal FQDN $OWAIntFQDN"
  [array]$CertNames += $OWAIntFQDN

  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange OWA External FQDN"
  $OWAExtFQDN = ((Get-OwaVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange OWA ExternalFQDN $OWAExtFQDN"
  [array]$CertNames += $OWAExtFQDN
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange OWA FQDNs" "$ErrorDetails"
 }

#MAPI
 try
 {
  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange MAPI Internal FQDN"
  $MAPIIntFQDN = ((Get-MapiVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange MAPI Internal FQDN $MAPIIntFQDN"
  [array]$CertNames += $MAPIIntFQDN

  Write-ACMELog "Exchange FQDNs" "Info" "Getting Exchange MAPI External FQDN"
  $MAPIExtFQDN = ((Get-MapiVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  Write-ACMELog "Exchange FQDNs" "Info" "Exchange MAPI External FQDN $MAPIExtFQDN"
  [array]$CertNames += $MAPIExtFQDN 
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error geting Exchange MAPI FQDNs" "$ErrorDetails"
 }

#Make FQDNs unique
 Write-ACMELog "Exchange FQDNs" "Info" "Make them unique"
 try
 {
  $CertNames = $CertNames | select -Unique
  if ($CertNames -match ".local" -or $CertNames -match ".intern")
   {
    Write-ACMELog "Exchange FQDNs" "Warning" "Unroutable Domains were found, sorted out"
    #Sort .local and .intern Domain Names out
    $CertNames = $CertNames | where -FilterScript {$_ -notmatch ".local"}
    $CertNames = $CertNames | where -FilterScript {$_ -notmatch ".intern"}
   }
  Write-ACMELog "Exchange FQDNs" "Info" "FQDNs are unique"
 }
 catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange FQDNs" "Error" "Error Can't make FQDNs unique" "$ErrorDetails"
 }
} else {
 Write-ACMELog "Custom FQDNs" "Info" "Using Custom FQDNs is configured"
 [array]$CertNames = $CustomFQDNs
}

#LE Stage or Prod System
 Write-ACMELog "LE System" "Info" "Setting LE Mode"
try {
 if ($LetsEncryptMode -eq "LE_Stage") {
  $LEMode = Set-PAServer LE_STAGE
  Write-ACMELog "LE System" "Info" "Setting LE Mode to STAGE MODE (TESTING ONLY)"
 }
 if ($LetsEncryptMode -eq "LE_Prod") {
  $LEMode = Set-PAServer LE_PROD
  Write-ACMELog "LE System" "Info" "Setting LE Mode to PRODUCTION MODE (LIVE SYSTEM)"
 }
 if ($LetsEncryptMode -ne "LE_Prod" -and $LetsEncryptMode -ne "LE_Stage") {
  Write-ACMELog "LE System" "ERROR" "LetsEncryptMode must set to LE_Prod or LE_Stage, please specify! Using LE_Stage to continue (TEST ONLY)"
  $LEMode = Set-PAServer LE_STAGE
 }
}
catch {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "LE System" "ERROR" "Can't set LE Mode: $ErrorDetails"
}

#Checking Let's Encrypt Account
Write-ACMELog "LE System" "Info" "Checking for existing LE Account"
try {
 $LEAccount = Get-PAAccount
 if ($LEAccount) {
  Write-ACMELog "LE System" "Info" "Found a existing LE Account"
 }
 if (!$LEAccount) {
  Write-ACMELog "LE System" "Warning" "No LE Account was found, creating a new one"
  $NewLEAccount = New-PAAccount -AcceptTOS -Contact $ContactMail
 }
}
catch {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "LE System" "ERROR" "No LE Account was found, Error Creating a new one: $ErrorDetails"
}

#Order a new certificate
Write-ACMELog "LE Certificate" "Info" "Trying to create a new order for a certificate"
try {
 $LEOrder = New-PAOrder $CertNames -PfxPass $PFXPasswort
 Write-ACMELog "LE Certificate" "Info" "Successfully ordered certificate"
}
catch {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "LE Certificate" "ERROR" "Can't order certificate: $ErrorDetails"
}

#Get Authorization information
Write-ACMELog "LE System" "Info" "Creating Autorisation files for LE verification"
try {
$auths = $LEOrder | Get-PAAuthorizations
$PublishAuths = $auths | Select @{L='Url';E={"http://$($_.fqdn)/.well-known/acme-challenge/$($_.HTTP01Token)"}},@{L='Filename';E={$($_.HTTP01Token)}},@{L='Body';E={Get-KeyAuthorization $_.HTTP01Token (Get-PAAccount)}}
foreach ($PublishAuth in $PublishAuths) {
 $filename = $AcmeFolder + "\" + $PublishAuth.Filename
 $authfile = out-file $filename -InputObject $PublishAuth.Body -Encoding ASCII
 #Write-ACMELog "LE System" "Info" "Successfully created authorisation file: $filename"
 }
}
catch {
 $ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "ERROR" "Can't create Autorisation files for LE verification" "$ErrorDetails"
}

#Notify LE Servers to check Authorization
Write-ACMELog "LE System" "Info" "Asking LE to verify the order"
try {
 $auths.HTTP01Url | Send-ChallengeAck
 Write-ACMELog "LE System" "Info" "Successfully informed LE to verify the order"
}
catch {
 $ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "ERROR" "Can't send ChallengeAck" "$ErrorDetails"
}

#Let's give LE some time to validate
Write-ACMELog "LE System" "INFO" "Let's give LE some time to validate (1 min)" "1 min"
try {
 start-sleep -Seconds 60
 Write-ACMELog "LE System" "INFO" "Time to wake up, need coffee!"
}
catch {
 Write-ACMELog "LE System" "ERROR" "I can't get no sleep" "Insomnia"
}


#Check Authorization Status
Write-ACMELog "LE System" "INFO" "Let's check the authorization"
try {
 $AuthError = 0
 $authstates = $LEOrder | Get-PAAuthorization
 foreach ($authstate in $authstates) {
  $authstatus = $authstate.HTTP01Status
  $authfqdn = $authstate.fqdn
  if ($authstatus -match "valid") {
   Write-ACMELog "LE System" "INFO" "Authorization for $authfqdn is valid"
   }
  else {
   Write-ACMELog "LE System" "ERROR" "Authorization for $authfqdn is invalid"
   $AuthError = $AuthError + 1
  }
 }
}
catch {
 $ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "ERROR" "Can't get authorization info" "$ErrorDetails"
 $AuthError = $AuthError + 1
}

if ($AuthError -ge 1) {
 Write-ACMELog "LE System" "ERROR" "Authorization failed"
 exit 
}

#Refresh the order
Write-ACMELog "LE System" "INFO" "Let's refresh the order"
try {
 $RefreshOrder = $LEOrder | Get-PAOrder -Refresh
}
catch {
 $ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "ERROR" "Can't refresh the order" "$ErrorDetails"
}

#Let's chgeck is certificate is ready to order
Write-ACMELog "LE System" "INFO" "Let's check if order is ready"
try {
 $RefreshOrderStatus = ($LEOrder | Get-PAOrder).Status
 if ($RefreshOrderStatus -match "ready") {
  Write-ACMELog "LE System" "INFO" "Order is ready"
 }
 else {
  Write-ACMELog "LE System" "ERROR" "Order is NOT ready"
  exit
 }
}
catch {
 ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "ERROR" "Can't check if order is ready" "$ErrorDetails"
 exit
}


#get the certificate
Write-ACMELog "LE System" "INFO" "Let's get the certificate"
try {
 $LECertificate = New-PACertificate $CertNames
 $LECertThumbprint = $LECertificate.Thumbprint
 Write-ACMELog "LE System" "INFO" "Getting certificate was successfull. Thumbprint is $LECertThumbprint"
}
catch {
 $ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "ERROR" "Getting certificate was not successfull" "$ErrorDetails"
 exit
}

#Verify if PFX is present
Write-ACMELog "LE System" "INFO" "Let's check if the PFX is present"
$Certpath = (Get-PACertificate | where {$_.Thumbprint -eq $LECertThumbprint}).PfxFile
if (test-path $CertPath)
 {
  Write-ACMELog "Cert Export" "Info" "PFX $LECertThumbprint verified successfully"
 }
else
 {
  Write-ACMELog "Cert Export" "Error" "failed to verify PFX $LECertThumbprint"
 }
 
#Let's remove the mime type
Write-ACMELog "LE System" "INFO" "CleanUp Mime Type"
try {
 $IISMimeType = Remove-WebConfigurationProperty  -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/staticContent" -Name "." -AtElement @{ fileExtension= '.' }
 Write-ACMELog "LE System" "INFO" "CleanUp successfull"
}
catch {
 $ErrorDetails = $_.Exception.Message
 Write-ACMELog "LE System" "Warning" "CleanUp unsuccessfull" "$ErrorDetails"
}

#Import and enable certificate for Exchange Server
Write-ACMELog "Exchange" "Info" "Lets try to enable certificate for Exchange Server"
try
 {
  [string]$ExchangeServerVersion = (Get-ExchangeServer $env:computername).Admindisplayversion
  Write-ACMELog "Exchange" "Info" "Exchange Server Version: $ExchangeServerVersion"
  $ImportPassword = ConvertTo-SecureString -String $PFXPasswort -Force -AsPlainText
  Import-ExchangeCertificate -FileName $CertPath -FriendlyName $SANAlias -Password $ImportPassword -PrivateKeyExportable:$true | Enable-ExchangeCertificate -Services "SMTP, IMAP, POP, IIS" -force
  Write-ACMELog "Exchange" "Info" "Successfully imported and enabled Certificate"
 }
catch
 {
  $ErrorDetails = $_.Exception.Message
  Write-ACMELog "Exchange" "Error" "Failed to import and enable Certificate" "$ErrorDetails"
 }

if ($SendMail -eq $true)
 {
  Write-ACMELog "SendMail" "Info" "Try to send email with logfile"
  try
   {
    Write-ACMELog "SendMail" "Info" "E-Mail send successfully initiated"
	Write-ACMELog "End" "Info" "End of script"
	if ($SMTPAuth -eq $false)
	 {
	  Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body -Attachments $LogName
	 }
	if ($SMTPAuth -eq $true)
	 {
	  $SecurePassword = $SMTPPassword | ConvertTo-SecureString -asPlainText -Force
	  $Creds = New-Object System.Management.Automation.PSCredential($SMTPUser,$SecurePassword)
	  Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body -Attachments $LogName -Credential $Creds
	 }
   }
  catch
   {
    $ErrorDetails = $_.Exception.Message
	Write-ACMELog "SendMail" "Error" "failed to send E-Mail" "$ErrorDetails"
	Write-ACMELog "End" "Info" "End of script"
   }
 }
else
 {
  Write-ACMELog "SendMail" "Info" "E-Mail settings are disabled"
  Write-ACMELog "End" "Info" "End of script"
 }