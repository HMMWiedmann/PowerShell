# Quelle 
# http://www.windows-infrastructure.de/installation-einer-zweistufigen-pki-two-tier-pki/

<#  Aufm DNS Server
    Host-A für Webserver (SubCA) erstellen pki.hm-lab.de
#>

#region Only RootCA CMDlets
# CAPolicy.inf unter %windir% ablegen

# RootCA installieren
Install-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType StandaloneRootCA `
                                   -KeyLength 4096 `
                                   -HashAlgorithmName SHA256 `
                                   -ValidityPeriod Years `
                                   -ValidityPeriodUnits 10 `
                                   -CACommonName 'HM-LAB-ROOTCA01' `
                                   -CryptoProviderName 'RSA#Microsoft Software Key Storage Provider' `
                                   -OverwriteExistingKey
# Überprüfen ob die CAPolicy gezogen wurde, beispielsweise bei den Sperrlisteneinstellungen

# Standardwerte für die Gültigkeit von Zertifikaten überprüfen
certutil -getreg ca\validityperiod
certutil -getreg ca\validityperiodunits

# Standardwert erhöhen
certutil -setreg ca\validityperiodunits 10

<# CDP (Sperrliste) konfigurieren

    lokale Partition: Standard %windir%\system32\CertSrv\CertEnroll\….
    - Sperrliste Veröffentlichen

    file://  (eine Abfrage über UNC Pfade funktioniert technisch nicht)
    - keine Option wählen

    ldap:  
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (z.B. spielwiese.local)
    - ldap:///CN=<CATruncatedName><CRLNameSuffix>,CN=<ServerShortName>,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,DC=HM-LAB,DC=DE
    - In CDP Erweiterung des ausgestellten Zertifikats einbeziehen
    
    http:// 
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (DNS Alias „pki“ auf Webserver)
    - http://pki.hm-lab.de/CertEnroll/<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl
    - In CDP Erweiterung des ausgestellten Zertifikats einbeziehen
#>

<# AIA (Zertifikatsinformationen) konfigurieren

    lokale Partition: Standard %windir%\system32\CertSrv\CertEnroll\….
    - keine Option wählen

    file://
    - keine Option wählen

    ldap:  
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (z.B. spielwiese.local)
    - ldap:///CN=<CATruncatedName>,CN=AIA,CN=Public Key Services,CN=Services,CN=Configuration,DC=HM-LAB,DC=DE
    - In AIA Erweiterung des ausgestellten Zertifikats einbeziehen

    http:// 
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (DNS Alias „pki“ auf Webserver)
    - http://pki.hm-lab.de/CertEnroll/<ServerDNSName>_<CaName><CertificateName>.crt
    - In AIA Erweiterung des ausgestellten Zertifikats einbeziehen

#>
Restart-Service -Name CertSrv -Force

# Zur Überprüfung von CDP und AIA
certutil -getreg  CA\CRLPublicationURLs
certutil -getreg  CA\CACertPublicationURLs
#endregion

#region Only SubCA CMDlets
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

New-Item -Path C:\inetpub\CertEnroll -ItemType Directory -Force
# C:\inetpub\CertEnroll als CertEnroll freigeben, Jeder mit ändern Berechtigen
# NTFS wird Cert Publisher (bzw. bei deutschem System Zertifikatsherausgeber) mit ändern berechigt

# Zum einfacheren Handling wird das Browsing der Website aktiviert, dazu navigiert man auf die Optionsseite des virtuellen Verzeichnisses –> Verzeichnis durchsuchen –> aktivieren

# Enable IIS Double Escaping, Abrufen von Deltasperrlisten, Ausführen in einer CMD
"cd %windir%\system32\inetsrv\"
"Appcmd set config „Default Web Site“ /section:system.webServer/Security/requestFiltering -allowDoubleEscaping:True"
"iisreset (neustart IIS)"
#endregion

#region Publish http und ldap
# Von der RootCA (C:\Windows\System32\CertSrv\CertEnroll liegen zwei Files, 
# ein .crl (Sperrliste) sowie ein .crt (Zertifikat)) auf die Subca (C:\inetpub\CertEnroll) kopieren

# Auf einem Memberserver oder Workstation mit LDAP Zugriff und Enterprise Admin Rechten
# Beispielsweise der SubCA
certutil -f -dspublish "<certificate_file>.crt"
certutil -f -dspublish "<revocation_list_file>.crl" "NETBios Name des RootCA Servers"
#endregion

#region Enterprise CA
# CAPolicy.inf der SubCA auf der SubCA unter %windir% platzieren
Add-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType EnterpriseSubordinateCA `
                                   -HashAlgorithmName SHA256 `
                                   -CryptoProviderName 'RSA#Microsoft Software Key Storage Provider' `
                                   -CACommonName HM-LAB-SUBCA01 `
                                   -ParentCA HMLABROOTCA01\HM-LAB-ROOTCA -OverwriteExistingKey
# Cert Req "C:\<request_file_name>.req" bei der RootCA signieren
# ausgestelltes Zertifikat anschauen und in eine Datei exportieren
# Bei der subca einreichen und den Dienst starten
# Überprüfen ob das neue SUBCA Cert gültig ist
certutil -URL "<certificate.crt>"
# Mehr details
certutil -f -verify -urlfetch "<certificate.crt>"

<# CDP (Sperrliste) konfigurieren

    lokale Partition: Standard %windir%\system32\CertSrv\CertEnroll\….
    - Sperrliste an diesem Ort veröffentlichen
    - Deltasperrlisten an diesem Ort veröffentlichen

    ldap:  
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (z.B. spielwiese.local)
    - ldap:///CN=<CATruncatedName><CRLNameSuffix>,CN=<ServerShortName>,CN=CDP,CN=Public Key Services,CN=Services,<ConfigurationContainer><CDPObjectClass>
    - Sperrliste an diesem Ort veröffentlichen
    - In alle Sperrlisten einbeziehen. Legt fest, …
    - In Sperrlisten einbeziehen. Wird z. Suche von Deltasperrlisten verwendet
    - In CDP-Erweiterung des ausgestellten Zertifikats einbeziehen
    - Deltasperrlisten an diesem Ort veröffentlichen
        
    http:// 
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (DNS Alias „pki“ auf Webserver)
    - http://pki.hm-lab.de/CertEnroll/<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl
    - In Sperrlisten einbeziehen. Wird z. Suche von Deltasperrlisten verwendet
    - In CDP-Erweiterung des ausgestellten Zertifikats einbeziehen

    file:\\
    - file:\\pki.hm-lab.de\Certenroll\<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl
    - Sperrliste an diesem Ort veröffentlichen
    - Deltasperrlisten an diesem Ort veröffentlichen
#>

<# AIA (Zertifikatsinformationen) konfigurieren

    lokale Partition: Standard %windir%\system32\CertSrv\CertEnroll\….
    - keine Option wählen

    file://
    - keine Option wählen

    ldap:  
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (z.B. hm-lab.de)
    - ldap:///CN=<CATruncatedName>,CN=AIA,CN=Public Key Services,CN=Services,<ConfigurationContainer><CAObjectClass>
    - In AIA Erweiterung des ausgestellten Zertifikats einbeziehen

    http:// 
    - Eintrag entfernen, und an die Domäne angepassten Eintrag setzen (DNS Alias „pki“ auf Webserver)
    - http://pki.hm-lab.de/CertEnroll/<ServerDNSName>_<CaName><CertificateName>.crt
    - In AIA Erweiterung des ausgestellten Zertifikats einbeziehen

#>
#endregion


# autoenroll per gpo aktivieren