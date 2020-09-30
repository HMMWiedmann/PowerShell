function Get-ExchangeVersion
{
    try {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
        $ExVer = (Get-ExchangeServer).AdminDisplayVersion

        if ($ExVer.Major -eq 15 -and $ExVer.Minor -eq 2)
        {
            Write-Host "2019" -ForegroundColor Red
            $EXVersion = "2019"
        }
        elseif($ExVer.Major -eq 15 -and $ExVer.Minor -eq 1)
        {
            Write-Host "2016" -ForegroundColor Red
            $EXVersion = "2016"
        }
        elseif($ExVer.Major -eq 15 -and $ExVer.Minor -eq 0)
        {
            Write-Host "2013" -ForegroundColor Red
            $EXVersion = "2013"
        }
        elseif($ExVer.Major -eq 14)
        {
            Write-Host "2010" -ForegroundColor Red
            $EXVersion = "2010"
        }
        else
        {
            Write-Host "unbekannt"
            $EXVersion = "unbekannt"
        }
    }
    catch {
        Write-Host $PSItem.Exception.Message
    }
}