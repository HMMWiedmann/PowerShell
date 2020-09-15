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
##    Pruefen ob ein Image in einer VM geladen ist.                              ##
##                                                                               ##
###################################################################################

#Abfrage aller am Host gelisteter VMs
$arroVM = Get-VM;

#Kontrollvariable fuer Alarmierung am Skriptende; wenn $TRUE und Alarmierung aktiviert, Skriptende mit Exit 1001
$bDVDCheck = $FALSE;
#Abrufen der einzelnen VMs in Schleife
foreach ($oVM in $arroVM)
{
    #Abrufen der Laufwerksinformationen jeder VM
    $arroDVDInfo = Get-VMDvdDrive -VMName $oVM.VMName;
    #Abrufen der einzelnen Laufwerke als Objekt. Wenn ein Image eingebunden ist, ist die Eigenschaft des Objekts "DvdMediaType" nicht "None"
    foreach ($oDVD in $arroDVDInfo)
    {
        #Ein Image ist am Geraet gemounted. Ausgabe von Text an das Dashboard.
        if ($oDVD.DvdMediaType -ne "None")
        {
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
            $strOutput = "Es wurde ein eingebundenes Image entdeckt an " + $oDVD.VMName.ToString() + ". Der Pfad zum Image lautet " + $oDVD.Path;
            Write-Host $strOutput;
            Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
            $bDVDCheck = $TRUE;
        }
    }
}

#Pruefen ob alarmiert werden soll
if ($bDVDCheck -eq $TRUE)
{
    Exit 1001;
}
else
{
    Write-Host "Es wurde kein eingebundenes Image entdeckt."
    Exit 0;
}