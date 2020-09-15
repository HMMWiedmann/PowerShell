###################################################################################
##                                                                               ##
##    Die acmeo cloud-distribution GmbH & Co. KG uebernimmt keine Haftung        ##
##    fuer unmittelbare und mittelbare Schaeden aus der Benutzung von            ##
##    durch acmeo selbst erstelltem Programmcode (bspw. Skripte,                 ##
##    Bibliotheken, Programmteile, Programme). Die Benutzung des als             ##
##    Beta-Version herausgegebenen Programmcodes geschieht auf eigene Gefahr.    ##
##                                                                               ##
##    Erstellt von: Sebastian-Nicolae Matei                                      ##
##    Fragen an: support@acmeo.eu                                                ##
##                                                                               ##
##    Abfrage des Ereignisprotokolls eines Hypervisor. Das Skript wird per       ##
##    Parameter konfiguriert. Dazu uebergibt man im Textfeld "Befehlszeile" im   ##
##    Dashboard als ersten Parameter den Namen des Ereignisprotokolles an, das   ##
##    man abfragen moechte. Der zweite Parameter ist der Ereignistyp nach dem man##
##    sucht. Hier ist Error fuer Fehler oder Error_Warning fuer Fehler und       ##
##    Warnungen moeglich. Mit dem dritten Parameter bestimmt man die Taktung der ##
##    Pruefung. Es kann genutzt werden:                                          ##
##    5  ->  5 Minuten Takt -> 24/7-Pruefung                                     ##
##    15 -> 15 Minuten Takt -> 24/7-Pruefung                                     ##
##    24 -> 24 Stunden Takt -> TSC                                               ##
##    Der vierte Parameter bestimmt ob die Pruefung alarmiert oder nicht. Der    ##
##    Parameter Alert aktiviert den Alarmierungsmodus.                           ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Microsoft-Windows-Hyper-V-VMMS Error 5 On"                                ##
##    Prueft das Ereignisprotokoll Microsoft-Windows-Hyper-V-VMMS auf Fehler     ##
##    in den letzten 5 Minuten und alarmiert bei Eintraegen.                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Microsoft-Windows-Hyper-V-Integration Error_Warning 24"                   ##
##    Prueft das Ereignisprotokoll Microsoft-Windows-Hyper-V-Integration auf     ##
##    Fehler und Warnungen in den letzten 24 Stunden und liefert diese als       ##
##    Ausgabe, ohne zu alarmieren.                                               ##
##                                                                               ##
###################################################################################
##                    Windows 2012 Hyper-V Ereignisprotokolle                    ##
###################################################################################
##    Microsoft-Windows-Hyper-V-Config                                           ##
##    Eintraege zu den Konfigurationsdateien der VMs.                            ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
##    - Operational                                                              ##
###################################################################################
##    Microsoft-Windows-Hyper-V-Hypervisor                                       ##
##    Eintraege zum Hypervisor.                                                  ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
##    - Operational                                                              ##
###################################################################################
##    Microsoft-Windows-Hyper-V-Integration                                      ##
##    Eintraege zu den Integrationsdiensten.                                     ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
###################################################################################
##    Microsoft-Windows-Hyper-V-SynthFC                                          ##
##    Eintraege zum virtuellen Fibre Channel.                                    ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
###################################################################################
##    Microsoft-Windows-Hyper-V-SynthNic                                         ##
##    Eintraege zu den virtuellen Netzwerkkarten.                                ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
###################################################################################
##    Microsoft-Windows-Hyper-V-SynthStor                                        ##
##    Eintraege zu den virtuellen Festplatten.                                   ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
##    - Operational                                                              ##
###################################################################################
##    Microsoft-Windows-Hyper-V-VMMS                                             ##
##    Eintraege zu den Managementdiensten der VMs.                               ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
##    - Networking                                                               ##
##    - Operational                                                              ##
##    - Storage                                                                  ##
###################################################################################
##    Hyper-V-Worker                                                             ##
##    Eintraege zum Worker-Prozess fuer den Betrieb der VMs.                     ##
##    Logs:                                                                      ##
##    - Admin                                                                    ##
###################################################################################
 
#Funktion wird genutzt, um bei Fund eines Ereignisses die Daten dazu an das Dashboard zu uebertragen
#Ausgabe an das Dashboard ueber CMDLet Write-Host
function fOutputEvent ($oLogEntry)
{
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    Write-Host "Ereignis-ID:"$oLogEntry.Id;
    Write-Host "Ereignis-Typ:"$oLogEntry.LevelDisplayName;
    Write-Host "Quelle:"$oLogEntry.ProviderName;;
    Write-Host "Zeit:"$oLogEntry.TimeCreated;
    Write-Host "Nachricht:"$oLogEntry.Message;
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";    
}
 
#Parameter aus dem Dashboard
#Ereignisprotokoll, das durchsucht werden soll
$strLog = $args[0];
#Ereignistypen, die gesucht werden sollen
$strLogLevel = $args[1];
#Zeitspanne, in der das Skript im Ereignisprotokoll zurueck suchen soll
$nClock = $args[2];
#Alarmierung, die mit Parameter "Alert" aktiviert wird
$strAlertMode = $args[3];
 
#Abfrage aktuelles Datum
$dtToday = Get-Date; 
#Erstellen des Objekts $dtCheck fuer Zeitspanne der Suche
$dtCheck;
#Zuweisen von Zeitspann an $dtCheck
switch ($nClock)
{
    5
    {
        $dtCheck = $dtToday.AddMinutes(-5);    
    }
    15
    {
        $dtCheck = $dtToday.AddMinutes(-15);
    }
    24
    {
        $dtCheck = $dtToday.AddDays(-1);
    }
}
 
#Kontrollvariable fuer Alarmierung am Skriptende; wenn $TRUE und Alarmierung aktiviert, Skriptende mit Exit 1001
$bAlertCheck = $FALSE;
#Unterscheidung der Abzufragenden Ereignisprotokolle
switch ($strLogLevel)
{
    #Nur Ereignisse vom Typ Fehler
    "Error"
    {
        #Text für formattierte Darstellung im Dashboard
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        Write-Host "FEHLER"
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        #Suche im Ereignisprotokoll nach Eintraegen mit Log.Level 2 (Fehler), die innerhalb der gesetzten Zeitspanne liegen
        $oarrLogEntries = Get-Winevent -LogName $strLog | Where-Object {$_.Level -eq 2 -and $_.TimeCreated -gt $dtCheck};
        #Bei Fund von Eintraegen, Ausgabe der Daten zum Ereignis im Dashboard und setzen der Kontrollvariable fuer Alarmierung.
        if($NULL -ne $oarrLogEntries)
        {
            #Uebergabe jedes Eintrags an die Funktion fOutput zur Ausgabe an das Dashboard
            foreach ($oLogEntry in $oarrLogEntries)
            {
 
                fOutputEvent($oLogEntry);
            }
            $bAlertCheck = $TRUE;
        }
        #Ausgabe von Text an das Dashboard, wurden keine Eintraege gefunden vom Typ Fehler
        else
        {
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
            Write-Host "Keine Eintraege gefunden vom Typ -Fehler- in"$strLog;
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        }
    }
    "Error_Warning"
    {
        #Text für formattierte Darstellung im Dashboard
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        Write-Host "FEHLER"
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        #Suche im Ereignisprotokoll nach Eintraegen mit Log.Level 2 (Fehler), die innerhalb der gesetzten Zeitspanne liegen
	$oarrLogEntries = Get-Winevent -LogName $strLog | Where-Object {$_.Level -eq 2 -and $_.TimeCreated -gt $dtCheck};
        #Bei Fund von Eintraegen, Ausgabe der Daten zum Ereignis im Dashboard und setzen der Kontrollvariable fuer Alarmierung.
        if($NULL -ne $oarrLogEntries)
        {
            #Uebergabe jedes Eintrags an die Funktion fOutput zur Ausgabe an das Dashboard
            foreach ($oLogEntry in $oarrLogEntries)
            {
 
                fOutputEvent($oLogEntry);
            }
            $bAlertCheck = $TRUE
        }
        #Ausgabe von Text an das Dashboard, wurden keine Eintraege gefunden vom Typ Fehler
        else
        {
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
            Write-Host "Keine Eintraege gefunden vom Typ -Fehler- in"$strLog;
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        }
        #Text für formattierte Darstellung im Dashboard
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        Write-Host "WARNUNGEN"
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        #Suche im Ereignisprotokoll nach Eintraegen mit Log.Level 3 (Warnung), die innerhalb der gesetzten Zeitspanne liegen
        $oarrLogEntries = Get-Winevent -LogName $strLog | Where-Object {$_.Level -eq 3 -and $_.TimeCreated -gt $dtCheck};
        #Bei Fund von Eintraegen, Ausgabe der Daten zum Ereignis im Dashboard und setzen der Kontrollvariable fuer Alarmierung.
        if($NULL -ne $oarrLogEntries)
        {
            foreach ($oLogEntry in $oarrLogEntries)
            {
 
                fOutputEvent($oLogEntry);
            }
            $bAlertCheck = $TRUE
        }
        #Ausgabe von Text an das Dashboard, wurden keine Eintraege gefunden vom Typ Warnung
        else
        {
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
            Write-Host "Keine Eintraege gefunden vom Typ -Warnung- in"$strLog;
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        }
    }
}
 
#Pruefen ob Alarmierung per Parameter aktiviert und ob alarmiert werden soll
if ($NULL -ne $strAlertMode -and $strAlertMode -eq "Alert" -and $bAlertCheck -eq $TRUE)
{
        Exit 1001;
}
else
{
    Exit 0;
}