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
##    Leistungsueberwachung des Hosts. Dieses Skript kann als taegliche          ##
##    Sicherheitspruefung oder 24/7-Ueberpruefung genutzt werden.                ##
##                                                                               ##
###################################################################################

#Daten zum Host abrufen
$oHost = Get-VMHost;

#Ausgabe an das Dashboard
Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
#Ausgabe Computername
Write-Host "Name:" $oHost.ComputerName;
#Ausgabe CPU Kerne
Write-Host "CPU Kerne:" $oHost.LogicalProcessorCount;
#Ausgabe zur Migration
Write-Host "Migration aktiviert:" $oHost.VirtualMachineMigrationEnabled;

#Abruf von Numa Topology fuer RAM Informationen
$arroHost = Get-VMHostNumaNode;

#Ausgabe installierter RAM
Write-Host "Ermittelter Arbeitsspeicher (MB):" $arroHost[0].MemoryTotal;

#Informationen zum primaeren VM Ressourcenpool abrufen fuer RAM Informationen
$oHost = Measure-VMResourcePool -Name "Primordial";
#Ausgabe durchschnittlich genutzter RAM
Write-Host "Durchschnittliche Speichernutzung (MB): " $oHost.AvgRAM;

$nCoreCounter = 1;
#Abfrage der Verfuegbarkeit der vorhandenen CPU Kerne und Ausgabe an das Dashboard.
foreach ($nAvailability in $arroHost[0].ProcessorsAvailability)
{
    Write-Host "Verfuegbarkeit - Kern " $nCoreCounter "(%): " $nAvailability;
    $nCoreCounter++;
}
#Ausgabe durchschnittliche CPU Nutzung
Write-Host "Durchschnittliche CPU-Nutzung (MHz): " $oHost.AvgCPU;
Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";