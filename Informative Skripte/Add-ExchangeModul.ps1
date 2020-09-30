function Add-ExchangeModul
{
    #Prüfen welche Exchange Version. Pfad aus Umgebungsvariable
    $EXVersion = $env:ExchangeInstallPath
    #Zerlegen bei jedem "\"
    $EXVersion = $EXVersion.split("\")
    #Länge des Arrays messen und 2 abziehen (Array startet bei 0 und die Umgebungsvariable endet mit "\")
    $EXVersionlanege = $EXVersion.length - 2
    #Exchange Version ist also der Letzte-2 Array Wert.
    $EXVersion = $EXVersion[$EXVersionlanege]
    if($EXVersion -eq "V15") { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn; }
    if($EXVersion -eq "V14") { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010; }
    if($EXVersion -eq "V8") { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin; }
}