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
##    Suche nach Snapshots aelter als angegebene Tage. Dazu uebergibt man im     ##
##    Textfeld "Befehlszeile" im Dashboard als ersten Parameter den Namwen der   ##
##    VM, deren Snapshots man pruefen moechte. Der zweite Parameter ist das      ##
##    maximale Alter des Snapshots in Tagen.                                     ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Exchange 12"                                                              ##
##    Sucht fuer VM Exchange nach Snapshots aelter als 12 Tage.                  ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Sharepoint 31"                                                            ##
##    Sucht fuer VM Sharepoint nach Snapshots aelter als 31 Tage.                ##
##                                                                               ##
###################################################################################
 
#Parameter aus dem Dashboard
#Name der VM
$strVMName = $args[0];
#Snapshotalter in Tagen
$strDays = $args[1];
 
#Suche nach Snapshots ueber gesetzte Parameter
$arroSnapshot = Get-VMSnapshot -VMName $strVMName;
 
#Abfrage aktuelles Datum
$dtToday = Get-Date;

#Kontrollvariable fuer Alarmierung am Skriptende; wenn $TRUE und Alarmierung aktiviert, Skriptende mit Exit 1001
$bSnapshotCheck = $FALSE;
 
#einzelne Snapshots aus Objekt-Array $arroSnapshot mit resp. Daten an das Dashboard ausgeben
foreach ($oSnapshot in $arroSnapshot)
{
    $dtDifference = $dtToday - $oSnapshot[0].CreationTime;
    if ($dtDifference.Days -gt $strDays)
    {
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        $strOutput = "Es wurde der Snapshot " + $oSnapshot.Name
        + " gefunden. Der Snapshot ist " + $dtDifference.Days
        + " Tage alt.";
        Write-Host $strOutput;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        $bSnasphotCheck = $TRUE;
    }
}
 
#Pruefen ob alarmiert werden soll
if ($bSnapshotCheck -eq $TRUE)
{
    Exit 1001;
}
else
{
    #Benachrichtigung fuer Benutzer erstellen und Ausgabe an das Dashboard wenn kein Image entdeckt wurde
    Write-Host "Es wurde kein Snapshot gefunden, der aelter als " $args[1] " Tage ist.";
    Exit 0;
}