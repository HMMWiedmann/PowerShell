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
##    Umzug von virtuellen Maschinen aus dem Dashboard. Dazu uebergibt man im    ##
##    Textfeld "Befehlszeile" im Dashboard als ersten Parameter den Namen der VM ##
##    Dashboard den Namen der virtuellen Maschine, die verschoben werden soll,   ##
##    die verschoben werden soll. Der zweite Parameter ist der Zielhost.         ##
##                                                                               ##
##    Dieses Skript aufgrund der Dauer als automatisierte Aufgabe nutzen.        ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Exchange Hyper-V2"                                                        ##
##    Verschiebt die VM Exchange auf den Host Hyper-V2.                          ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Sharepoint Hyper-V"                                                       ##
##    Verschiebt die VM Sharepoint auf den Host Hyper-V.                         ##
##                                                                               ##
###################################################################################

#Parameter aus dem Dashboard
#Name der VM
$strVMName = $args[0];
#Zielhost fuer VM
$strDestinationHost = $args[1];

#Der Prozess Repair-VM (muss vor Migration oder Export durchgefuehrt werden) wird gestartet und das Skript wartet, bis dieser abgeschlossen ist
$jobRepair = Start-Job { Repair-VM }
Wait-Job $jobRepair;

#Die Migration wird gestartet mit den gesetzten Parametern aus dem Dashboard
$jobMove = Start-Job { Move-VM -Name $strVMName -DestinationHost $strDestinationHost }
Wait-Job $jobMove;

#Abfrage aktuelles Datum
$dtNow = Get-Date;
#Benachrichtigung fuer Benutzer erstellen und Ausgabe an das Dashboard
$strOutput = "Die virtuelle Maschine " + $strVMName 
        + " wurde verschoben auf " + $strDestinationHost + " am " 
        + $dtNow.ToShortDateString() + ' ' + $dtNow.ToShortTimeString();

Write-Host $strOutput;