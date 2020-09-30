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
##    Aus dem Dashboard von einer virtuellen Maschine einen Snapshot erstellen.  ##
##    Dazu uebergibt man im Textfeld "Befehlszeile" im Dashboard als ersten      ##
##    Parameter den Namen der virtuellen Maschine, die gesichert werden soll.    ##
##    Der zweite Parameter ist die Bezeichnung des Snapshots.                    ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Exchange 01.01.2014"                                                      ##
##    Erstellt einen Snapshot der VM Exchange mit dem Titel 01.01.2014.          ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Sharepoint Sharepoint_Failover"                                           ##
##    Erstellt einen Snapshot der VM Sharepoint mit dem Titel                    ##
##    Sharepoint_Failover.                                                       ##
##                                                                               ##
###################################################################################

#Parameter aus dem Dashboard
#Name der VM
$strVMName = $args[0];
#Name des Snapshots
$strSnapshotname = $args[1];

#Der Snapshot wird angelegt mit den gesetzten Parametern aus dem Dashboard und das Skript wartet, bis der Vorgang abgeschlossen ist
$jobSnapshot = Start-Job { Checkpoint-VM -Name $strVMName -SnapshotName $strSnapshotname }
Wait-Job $jobSnapshot;

#Abfrage aktuelles Datum
$dtNow = Get-Date;
#Benachrichtigung fuer Benutzer erstellen und Ausgabe an das Dashboard
$strOutput = "Es wurde ein Snapshot von " + $strVMName 
+ " angelegt mit der Bezeichnung " + $strSnapshotname + " am " 
+ $dtNow.ToShortDateString() + ' ' + $dtNow.ToShortTimeString();

Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
Write-Host $strOutput;
Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";