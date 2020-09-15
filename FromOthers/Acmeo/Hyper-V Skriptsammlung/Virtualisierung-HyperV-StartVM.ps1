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
##    Einzelne VM oder saemtliche VMs eines Hosts starten. Dazu uebergibt        ##
##    man im Textfeld "Befehlszeile" im Dashboard den Namen der VM, die man      ##
##    starten moechte. Alternativ kann der Parameter start_all genutzt 	         ##
##    werden um alle VMs zu starten.                                             ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Exchange"                                                                 ##
##    Startet die VM Exchange.	                                                 ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "start_all"                                                             	 ##
##    Startet alle VMw dieses Hosts.		                                 ##
##                                                                               ##
###################################################################################

#Name der VM
$strVMName = $args[0];

#einzelne VM starten
if ($strVMName -ne "start_all")
{
    Start-VM –Name $strVMName;
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    $strOutput = $strVMName + " wurde gestartet.";
    Write-Host $strOutput;
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
}
#Bei Parameter "start_all" alle VMs starten
else
{
    #Abfrage aller VMs
    $oarrVM = Get-VM;
    foreach ($oVM in $oarrVM)
    {
        #Starten der jeweiligen VM und Ausgabe an das Dashboard
        Start-VM –Name $oVM.VMName;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        $strOutput = $oVM.VMName + " wurde gestartet.";
        Write-Host $strOutput;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    }
}