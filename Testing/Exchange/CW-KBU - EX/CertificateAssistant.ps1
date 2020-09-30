Param(
  [bool]$Renew
)

clear
write-host ""
write-host "----------------------------------------------------------------"
write-host "
   _______                   _    ___ _                         
  (_______)              _  (_)  / __|_)              _         
   _       _____  ____ _| |_ _ _| |__ _  ____ _____ _| |_ _____ 
  | |     | ___ |/ ___|_   _) (_   __) |/ ___|____ (_   _) ___ |
  | |_____| ____| |     | |_| | | |  | ( (___/ ___ | | |_| ____|
   \______)_____)_|      \__)_| |_|  |_|\____)_____|  \__)_____)
   _______           _                             
  (_______)         (_)       _                _   
   _______  ___  ___ _  ___ _| |_ _____ ____ _| |_ 
  |  ___  |/___)/___) |/___|_   _|____ |  _ (_   _)
  | |   | |___ |___ | |___ | | |_/ ___ | | | || |_ 
  |_|   |_(___/(___/|_(___/   \__)_____|_| |_| \__)
" -foregroundcolor cyan
write-host ""
write-host "  Certificate Assistant v1.1"
write-host "  Automatische Let's Encrypt Zertifikate für Exchange 2010/2013/2016"
write-host ""
write-host "  Frank Zoechling (www.FrankysWeb.de)"
write-host ""
write-host "----------------------------------------------------------------"

#ACME Sharp Modul laden
write-host "  Lade ACMESharp Modul..."
Import-Module ACMESharp -ea 0
$CheckACMEModule = get-module ACMESharp
 if (!$CheckACMEModule)
  {
   write-host "  Warnung: ACME Sharp Module nicht gefunden" -foregroundcolor yellow
   write-host "           Versuche ACMESharp Modul zu installieren..." -foregroundcolor yellow
   Install-Module -Name ACMESharp -RequiredVersion 0.8.1 -AllowClobber #Modul in einer bestimmten Version wird installiert
   Import-Module ACMESharp -ea 0
   $CheckACMEModule = get-module ACMESharp
   if (!$CheckACMEModule)
    {
	  write-host "  Fehler: ACME Sharp Modul konnte nicht installiert werden" -foregroundcolor red
      exit
	}
  }

#IIS PowerShell Modul laden
write-host "  Lade IIS Webadministration Modul..."
Import-Module Webadministration -ea 0
 $CheckIISModule = get-module Webadministration
  if (!$CheckIISModule)
   {
    write-host "  Webadministration Module nicht gefunden" -foregroundcolor red
	exit
   }

#IIS SnapIn laden
write-host "  Lade Exchange Management Shell..."
Add-PSSnapin *exchange* -ea 0
$CheckExchangeSnapin = Get-PSSnapin *exchange*
 if (!$CheckExchangeSnapin)
  {
   write-host "  Exchange SnapIn nicht gefunden" -foregroundcolor red
   exit
  }

#Exchange-Version erkennen
$ExchangeVersion = (Get-ExchangeServer -Identity $env:COMPUTERNAME | ForEach {$_.AdminDisplayVersion})
 if ($ExchangeVersion -match "Version 15")
 {
  write-host "  Exchange Server 2013/2016 wurde erkannt"
 }
 elseif ($ExchangeVersion -match "Version 14")
 {
  write-host "  Exchange Server 2010 wurde erkannt"
 }
 else
 {
  write-host "   Keine unterstützte Exchange Server Version wurde gefunden. Script wird beendet." -foregroundcolor Red
  exit
 }
    
if ($ExchangeVersion -match "Version 14" -Or $ExchangeVersion -match "Version 15") 
 {
  if ($renew -ne $True)
  {
  #Konfgurierte DNS-Namen abfragen
  write-host ""
  write-host "  Lese Exchange Konfiguration..."
  $ExchangeServer = (Get-ExchangeServer $env:computername).Name
   [array]$CertNames += ((Get-ClientAccessServer -Identity $ExchangeServer).AutoDiscoverServiceInternalUri.Host).ToLower()  
   [array]$CertNames += ((Get-OutlookAnywhere -Server $ExchangeServer).ExternalHostname.Hostnamestring).ToLower() 
   [array]$CertNames += ((Get-OabVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
   [array]$CertNames += ((Get-OabVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
   [array]$CertNames += ((Get-ActiveSyncVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
   [array]$CertNames += ((Get-ActiveSyncVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
   [array]$CertNames += ((Get-WebServicesVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
   [array]$CertNames += ((Get-WebServicesVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
   [array]$CertNames += ((Get-EcpVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
   [array]$CertNames += ((Get-EcpVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
   [array]$CertNames += ((Get-OwaVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
   [array]$CertNames += ((Get-OwaVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower()
  if ($ExchangeVersion -match "Version 15")
   {
    [array]$CertNames += ((Get-OutlookAnywhere -Server $ExchangeServer).Internalhostname.Hostnamestring).ToLower() 
    [array]$CertNames += ((Get-MapiVirtualDirectory -Server $ExchangeServer).Internalurl.Host).ToLower()
    [array]$CertNames += ((Get-MapiVirtualDirectory -Server $ExchangeServer).ExternalUrl.Host).ToLower() 
   }
  [array]$CertNames = "mail.koehler-wildberg.de"
  [array]$CertNames += "autodiscover.koehler-wildberg.de"
  $CertNames = $CertNames | select –Unique

  write-host "----------------------------------------------------------------"
  write-host ""
  write-host "  Die folgenden DNS-Namen wurden gefunden:"
  write-host ""
  foreach ($Certname in $CertNames)
   {
    write-host "  $certname" -foregroundcolor cyan
   }
  write-host ""

  #Weitere Namen hinzufügen?
  $AddName = "j"
  while ($AddName -match "j")
   {
    $AddName = read-host "  Sollen dem Zertifikat weitere DNS-Namen hinzugefügt werden? (j/n)"
    if ($AddName -match "j")
     {
  	  $AddHost = read-host "  Bitte DNS-Namen eingeben"
 	  $CertNames += "$addhost"
     }
   }

  #Ausgabe der DNS Namen
  write-host ""
  write-host "  Die folgenden DNS Namen wurden konfiguriert:"
  write-host ""
  foreach ($Certname in $CertNames)
   {
    write-host "  $certname" -foregroundcolor cyan
   }
  write-host ""

  #Email-Adresse für die ACME Registration
  write-host "  Welche E-Mail Adresse soll für die Registrierung bei Let's Encrypt verwendet werden?"
  write-host ""
  write-host "  Wenn bereits eine Let's Encrypt Registrierung auf diesem Computer durchgeführt"
  write-host "  wurde, muss keine E-Mail Adresse angegeben werden."
  write-host
  $contact = read-host "  E-Mail Adresse"
  $contactmail = "mailto:$contact"
  write-host

  #Task zum erneuern hinzufügen?
  write-host "  Soll eine geplante Aufgabe für das automatische Erneuern des Zertifikats"
  write-host "  angelegt werden?"
  write-host ""
  $AutoRenewTask = read-host "  Automatische Erneuerung? (j/n)"
  if ($AutoRenewTask -match "j")
   {
    $username = read-host "  Benutzername für den Task (Domain\Benutzer)"
    $SecurePassword = read-host "  Passwort" -AsSecureString
   }
  write-host ""

  #----------------------------------------------

  #Task zum Erneuern anlegen
  if ($AutoRenewTask -match "j")
   {
    $installpath = (get-location).Path
  
    #Geplante Aufgabe anlegen
    $zeitpunkt = "23:00"
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $startTime = "$zeitpunkt" | get-date -format s

    $taskService = New-Object -ComObject Schedule.Service 
    $taskService.Connect() 
  
    $rootFolder = $taskService.GetFolder($NULL) 

    $taskDefinition = $taskService.NewTask(0) 
  
    $registrationInformation = $taskDefinition.RegistrationInfo 
  
    $registrationInformation = $taskDefinition.RegistrationInfo 
    $registrationInformation.Description = "Let's Encrypt Zertifikatserneuerung - www.FrankysWeb.de"
    $registrationInformation.Author = $username
  
    $taskPrincipal = $taskDefinition.Principal 
    $taskPrincipal.LogonType = 1 
    $taskPrincipal.UserID = $username
    $taskPrincipal.RunLevel = 0 
  
    $taskSettings = $taskDefinition.Settings 
    $taskSettings.StartWhenAvailable = $true
    $taskSettings.RunOnlyIfNetworkAvailable = $true
    $taskSettings.Priority = 7 
  
    $taskTriggers = $taskDefinition.Triggers 
   
    $executionTrigger = $taskTriggers.Create(2)  
    $executionTrigger.StartBoundary = $startTime
  
    $taskAction = $taskDefinition.Actions.Create(0) 
    $taskAction.Path = "powershell.exe"
    $taskAction.Arguments = "-Command `"&'$installpath\CertificateAssistant.ps1' -renew:`$true`""
 
    $job = $rootFolder.RegisterTaskDefinition("Let's Encrypt Zertifikatserneuerung (www.FrankysWeb.de)" , $taskDefinition, 6, $username, $password, 1) 
   }

  #----------------------------------------------
  clear
  write-host ""
  write-host "---------------------------------------------------------------------------" -foregroundcolor green
  write-host "Alle Informationen sind vorhanden, soll das Zertifikat konfiguriert werden?" -foregroundcolor green
  write-host "---------------------------------------------------------------------------" -foregroundcolor green
  write-host ""
  read-host "Konfiguration starten? (Enter für Weiter / STRG+C zum Abbrechen"
  write-host ""

  #Prüfen ob Vault existiert
  write-host "Prüfe ob bereits ein Vault existiert..."
  $Vault = Get-ACMEVault
  if (!$Vault)
   {
    write-host "Kein Vault gefunden, versuche neuen Vault anzulegen..."
    $CreateVault = Initialize-ACMEVault
    sleep 1
    $Vault = Get-ACMEVault
    if (!$Vault)
     {
      write-host "Fehler: Vault konnte nicht erzeugt werden" -foregroundcolor red
  	  exit
     }
   }
 
  #Prüfen ob Let's Encrypr Registrierung vorhanden ist
  write-host "Prüfe Let's Encrypt Registrierung..."
  $Registration = Get-ACMERegistration
  if (!$Registration)
   {
    write-host "Wsrnung: Es wurde keine Registrierung bei Let's Encrypt gefunden, neue Registrierung wird durchgeführt" -foregroundcolor yellow
    $Registration = New-ACMERegistration -Contacts $contactmail -AcceptTos
    if (!$Registration)
     {
      write-host "Fehler: Es konnte keine Registrierung bei Let's Encrypt durchgeführt werden" -foregroundcolor red
 	 exit
     }
    else
     {
      write-host "Registrierung bei Let's Encrypt wurde durchgeführt" -foregroundcolor green
     }
   }

  #Domain Names Validierung vorbereiten
  $CertSubject = ((Get-OutlookAnywhere -Server $ExchangeServer).ExternalHostname.Hostnamestring).ToLower()
  $ExchangeSANID = 1
  foreach ($ExchangeSAN in $CertNames)
   {
    $CurrentDate = get-date -format ddMMyyyyhhmm #CurrentDate um Uhrzeit ergänzt
    $ACMEAlias = "Cert" + "$CurrentDate" + "-" + "$ExchangeSANID"
    $ExchangeSANID++
 
    write-host "Neuer Identifier:"
    write-host " DNS: $ExchangeSAN"
    write-host " Alias: $ACMEAlias"
    $NewID = New-ACMEIdentifier -Dns $ExchangeSAN -Alias $ACMEAlias
    write-host "Validierung vorbereiten:"
    write-host " Alias $ACMEAlias"
    $ValidateReq = Complete-ACMEChallenge $ACMEAlias -ChallengeType http-01 -Handler iis -HandlerParameters @{ WebSiteRef = 'Default Web Site' }
    [Array]$ACMEAliasArray += $ACMEAlias
    if ($ExchangeSAN -eq $CertSubject) {$SubjectAlias = $ACMEAlias}
   }
 
  #Let's Encrypt IIS Verzeichnis auf HTTP umstellen
  write-host "Let's Encrypt IIS Verzeichnis auf HTTP umstellen..."
  $IISDir = Set-WebConfigurationProperty -Location "Default Web Site/.well-known" -Filter 'system.webserver/security/access' -name "sslFlags" -Value None
  $IISDirCeck = (Get-WebConfigurationProperty -Location "Default Web Site/.well-known" -Filter 'system.webserver/security/access' -name "sslFlags").Value
  if ($IISDirCeck -match 0)
   {
    write-host "Umstellung auf HTTP erfolgreich" -foregroundcolor green
   }
  else
   {
    write-host "Fehler: Umstellung auf HTTP war nicht erfolgreich" -foregroundcolor red
    exit
   }

  #Domain Namen validieren
  write-host "DNS Namen durch Let's Encrypt validieren lassen..."
  foreach ($ACMEAlias in $ACMEAliasArray)
   {
    write-host "Validierung durchführen: $ACMEAlias"
    $Validate = Submit-ACMEChallenge $ACMEAlias -ChallengeType http-01
   }

  write-host "30 Sekunden warten..."
  sleep -seconds 30

  #Validierung prüfen
  write-host "Prüfe ob die DNS-Namen validiert wurden..."
  foreach ($ACMEAlias in $ACMEAliasArray)
   {
    write-host "Update Alias: $ACMEAlias"
    $ACMEIDUpdate = Update-ACMEIdentifier $ACMEAlias
    $ACMEIDStatus = $ACMEIDUpdate.Status
    if ($ACMEIDStatus -eq "valid")
     {
      write-host "Validierung OK" -foregroundcolor green
     }
    else
     {
      write-host "Fehler: Validierung für Alias $ACMEAlias fehlgeschlagen" -foregroundcolor red
	  #exit
     }
   }

  #Zertifikat vorbereiten und einreichen
  $SANAlias = "SAN" + "$CurrentDate"
  $NewCert = New-ACMECertificate $SubjectAlias -Generate -AlternativeIdentifierRefs $ACMEAliasArray -Alias $SANAlias
  $SubmitNewCert = Submit-ACMECertificate $SANAlias

  #Warten bis das Zertifikat ausgestellt wurde
  write-host "30 Sekunden warten..."
  sleep -seconds 30

  #Status prüfen
  write-host "Prüfe das Zertifikat..."
  $UpdateNewCert = Update-ACMECertificate $SANAlias
  $CertStatus = (Get-ACMECertificate $SANAlias).CertificateRequest.Statuscode
  sleep 5
  if ($CertStatus -match "OK")
   {
    write-host "Zertifikat OK" -foregroundcolor green
   }
  else
   {
    write-host "Fehler: Zertifikat wurde nicht ausgestellt" -foregroundcolor red
    exit
   }

  #Zertifikat aus Vault exportieren und Exchange zuweisen
  write-host "Exportiere das Zertifikat nach $env:temp"
  $CertPath = "$env:temp" + "\" + "$SANAlias" + ".pfx"
  $PFXPasswort = Get-Random -Minimum 1000000 -Maximum 9999999
  $CertExport = Get-ACMECertificate $SANAlias -ExportPkcs12 $CertPath -CertificatePassword $PFXPasswort
  write-host "Prüfe ob das Zertifikat exportiert wurde..."
  if (test-path $CertPath)
   {
    write-host "Zertifikat wurde erfolgreich exportiert" -foregroundcolor green
	write-host "Passwort für die PFX Datei: $PFXPasswort"
   }
  else
   {
    write-host "Fehler: Das Zertifikat wurde nicht exportiert" -foregroundcolor red
    exit
   }

  write-host "Zertifikat wird Exchange zugewiesen und aktiviert"
  $ImportPassword = ConvertTo-SecureString -String $PFXPasswort -Force –AsPlainText
  if ($ExchangeVersion -match "Version 15")
  { 
   Import-ExchangeCertificate -FileName $CertPath -FriendlyName $ExchangeSubject -Password $ImportPassword -PrivateKeyExportable:$true | Enable-ExchangeCertificate -Services "SMTP, IMAP, POP, IIS" –force
  }
  elseif ($ExchangeVersion -match "Version 14")
  {
   Import-ExchangeCertificate -FileData ([Byte[]]$(Get-Content -Path $CertPath -Encoding byte -ReadCount 0)) -FriendlyName $ExchangeSubject -Password $ImportPassword -PrivateKeyExportable:$true | Enable-ExchangeCertificate -Services "SMTP, IMAP, POP, IIS" -force
  }
  write-host "Prüfe ob das Zertifikat aktiviert wurde"
  $CurrentCertThumbprint = (Get-ChildItem -Path IIS:SSLBindings | where {$_.port -match "443" -and $_.IPAddress -match "0.0.0.0" } | select Thumbprint).Thumbprint
  $ExportThumbprint = $CertExport.Thumbprint
  if ($CurrentCertThumbprint -eq $ExportThumbprint)
   {
    write-host "Das Zertifikat wurde erfolgreich aktiviert" -foregroundcolor green
   }
  else
   {
    write-host "Aktivierung ist fehlgeschlagen" -foregroundcolor red
    exit
   } 
  }

  #---------------------------------------ERNEUERN------------------------------------------------
  #Automatische Erneuerung
  if ($renew -eq $True)
  {
   $PFXPasswort = Get-Random -Minimum 1000000 -Maximum 9999999
 
   $CurrentCertThumbprint = (Get-ChildItem -Path IIS:SSLBindings | where {$_.port -match "443" -and $_.IPAddress -match "0.0.0.0" } | select Thumbprint).Thumbprint
   $ExchangeCertificate = Get-ExchangeCertificate -Thumbprint $CurrentCertThumbprint
   $ExchangeSANs = ($ExchangeCertificate.CertificateDomains).Address
   $ExchangeSubject = $ExchangeCertificate.Subject.Replace("CN=","")

   if ($ExchangeSANs -notcontains $ExchangeSubject) {$ExchangeSANs += $ExchangeSubject}

   $CurrentDate = get-date
   $VaildTill = $ExchangeCertificate.NotAfter
   $DaysLeft = ($VaildTill - $CurrentDate).Days
   if ($DaysLeft -le 4)		#4 Tage vor Ablauf erneuern
    {
     $ExchangeSANID = 1
     foreach ($ExchangeSAN in $ExchangeSANs)
      {
       $CurrentDate = get-date -format ddMMyyyy
       $ACMEAlias = "Cert" + "$CurrentDate" + "-" + "$ExchangeSANID"
       $ExchangeSANID++
       New-ACMEIdentifier -Dns $ExchangeSAN -Alias $ACMEAlias
       Complete-ACMEChallenge $ACMEAlias -ChallengeType http-01 -Handler iis -HandlerParameters @{ WebSiteRef = 'Default Web Site' }
       [Array]$ACMEAliasArray += $ACMEAlias
       if ($ExchangeSAN -match $ExchangeSubject) {$ExchangeSubjectAlias = $ACMEAlias}
      }

     foreach ($ACMEAlias in $ACMEAliasArray)
      {
       Submit-ACMEChallenge $ACMEAlias -ChallengeType http-01
      }

     sleep -seconds 30

     foreach ($ACMEAlias in $ACMEAliasArray)
      {
       Update-ACMEIdentifier $ACMEAlias
      }

     $SANAlias = "SAN" + "$CurrentDate"
     New-ACMECertificate $ExchangeSubjectAlias -Generate -AlternativeIdentifierRefs $ACMEAliasArray -Alias $SANAlias
     Submit-ACMECertificate $SANAlias

     sleep -seconds 30

     Update-ACMECertificate $SANAlias
     
     $CertPath = "$env:temp" + "\" + "$SANAlias" + ".pfx"
     $CertExport = Get-ACMECertificate $SANAlias -ExportPkcs12 $CertPath -CertificatePassword $PFXPasswort
 
     $ImportPassword = ConvertTo-SecureString -String $PFXPasswort -Force –AsPlainText
     if ($ExchangeVersion -match "Version 15")
      { 
       Import-ExchangeCertificate -FileName $CertPath -FriendlyName $ExchangeSubject -Password $ImportPassword -PrivateKeyExportable:$true | Enable-ExchangeCertificate -Services "SMTP, IMAP, POP, IIS" –force
      }
     elseif ($ExchangeVersion -match "Version 14")
      {
       Import-ExchangeCertificate -FileData ([Byte[]]$(Get-Content -Path $CertPath -Encoding byte -ReadCount 0)) -FriendlyName $ExchangeSubject -Password $ImportPassword -PrivateKeyExportable:$true | Enable-ExchangeCertificate -Services "SMTP, IMAP, POP, IIS" -force
      }
    }
  }
}
