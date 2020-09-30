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
##    Export einer virtuellen Maschine aus dem Dashboard in lokalen Pfad.        ##
##    Dazu übergibt man im Textfeld "Befehlszeie" im Dashboard als ersten        ##
##    Parameter den Namen der VM, die exportiert werden soll. Der zweite         ##
##    Parameter ist der Pfad in den exportiert werden soll.                      ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Exchange D:\Export_Exchange\ "                                            ##
##    Exportiert die VM Exchange. Snapshots und vHDs werden in Ordner            ##
##    D:\Export_Exchange\ kopiert.                                               ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Sharepoint C:\Sharepoint_Export\"                                         ##
##    Exportiert die VM Sharepoint. Snapshots und vHDs werden in Ordner          ##
##    D:\Sharepoint_Export\ kopiert.                                             ##
##                                                                               ##
###################################################################################

#Parameter aus dem Dashboard
#Name der VM
$strVMName = $args[0];
#Pfad fuer Export
$strPath = $args[1];

#Der Prozess Repair-VM (muss vor Migration oder Export durchgefuehrt werden) wird gestartet und das Skript wartet,  bis der Vorgang abgeschlossen ist.
$jobRepair = Start-Job { Repair-VM }
Wait-Job $jobRepair;

#Der Export wird gestartet mit den gesetzten Parametern aus dem Dashboard und das Skript wartet, bis der Vorgang abgeschlossen ist.
$jobExport = Start-Job { Export-VM -Name $strVMName -Path $strPath }
Wait-Job $jobExport;

#Abfrage aktuelles Datum
$dtNow = Get-Date;
#Benachrichtigung fuer Benutzer erstellen und Ausgabe an das Dashboard
$strOutput = "Es wurde ein Export von " + $strVMName 
+ " durchgeführt in den Pfad " + $strPath + " am " 
+ $dtNow.ToShortDateString() + ' ' + $dtNow.ToShortTimeString();

Write-Host $strOutput;