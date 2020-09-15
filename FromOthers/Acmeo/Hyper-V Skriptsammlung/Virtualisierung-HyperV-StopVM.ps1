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
##    Einzelne VM oder saemtliche VMs eines Hosts herunterfahren. Dazu uebergibt ##
##    man im Textfeld "Befehlszeile" im Dashboard den Namen der VM, die man      ##
##    herunterfahren moechte. Alternativ kann der Parameter shutdown_all genutzt ##
##    werden um alle VMs herunter zu fahren.                                     ##
##                                                                               ##
###################################################################################
##                                                                               ##
##    Beispiele fuer moeglich Parameter aus der Befehlszeile                     ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "Exchange"                                                                 ##
##    Faehrt die VM Exchange herunter.                                           ##
##                                                                               ##
##    Befehlszeile:                                                              ##
##    "shutdown_all"                                                             ##
##    Faehrt alle VMs dieses Hosts herunter.                                     ##
##                                                                               ##
###################################################################################

#Name der VM
$strVMName = $args[0];

#einzelne VM stoppen
if ($strVMName -ne "shutdown_all")
{
    Stop-VM –Name $strVMName –TurnOff -Force;
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    $strOutput = $strVMName + " wurde heruntergefahren.";
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
        #Stoppen der jeweiligen VM und Ausgabe an das Dashboard
        Stop-VM –Name $oVM.VMName –TurnOff -Force;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        $strOutput = $oVM.VMName + " wurde heruntergefahren.";
        Write-Host $strOutput;
        Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    }
}