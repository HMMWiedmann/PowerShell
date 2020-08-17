<# 
    Beschreibung:
    ueberprueft das Attribut "LastWriteTime" von Veeam Backupdateien auf einer USB-Platte (Remote)

    Nutzungshinweise:
    FullBackupMaxDays        - Anzahl der Tage die das Full Backup nicht gelaufen sein muss, Beispiel 7 (Tage)
    IncrementalBackupMaxDays - Anzahl der Tage die das Inkrementelle Backup nicht gelaufen sein muss, Beispiel 1 (Tage)
    BackupNetworkPath        - Netzwerkpfad zur Backupablage, Beispiel \\10.22.0.6\USBDisk1\Veeam-Backup_USBDisk1
    UserName                 - Benutzername fuer den Zugriff auf die Backupdateien
    Password                 - Passwort des Benutzers
    TotalDiskSizeInBytes     - Größe der USB-Platte in Bytes, Beispiel 4398046511104 # entspricht 4TB
    MaxUsedSizeInPercent     - Prozentuale Angabe zum genutzten Speicher der Platte, Beispiel 70

    Outputparameter:
    FBDateDiff
    IBDateDiff
    PercentOutput
#>

[string]$UserName
[System.Security.SecureString]$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

try 
{
    $PSDriveName = "QNAPTempDrive"
        
    $ShareReadCred = New-Object -TypeName System.Management.Automation.PSCredential ($UserName, $SecurePassword)
    New-PSDrive -Name $PSDriveName -PSProvider FileSystem -Credential $ShareReadCred -Root $BackupNetworkPath | Out-Null
    
    # Check LastWriteTime of Backups
    $VMFolders = Get-ChildItem -Path "$($PSDriveName):\" | `
                 Where-Object -Property Name -NE "# Recovery Media" | `
                 Where-Object -Property Name -NE "VeeamConfigBackup" | `
                 Where-Object -Property Name -NotLike "Backup*" |
                 Where-Object -Property Length -EQ $null
    $Date = Get-Date

    $FBItems = @()
    $IBItems = @()

    foreach($VM in $VMFolders)
    {      
        $FBItems = $FBItems + (Get-ChildItem -Path $VM.FullName -Recurse -Include *.vbk)
        $IBItems = $IBItems + (Get-ChildItem -Path $VM.FullName -Recurse -Include *.vib)

        $LastFB = ($FBItems | Sort-Object -Property LastWriteTime -Descending -ErrorAction SilentlyContinue)[0].LastWriteTime 
        $LastIB = ($IBItems | Sort-Object -Property LastWriteTime -Descending -ErrorAction SilentlyContinue)[0].LastWriteTime

        
        if($null -ne $LastFB)
        {
            $FBDateDiff = ($Date - $LastFB).Days
        }
        if($null -ne $IBItems)
        {
            $IBDateDiff = ($Date - $LastIB).Days
        }
    }

    # Check remaining Size
    $items = Get-ChildItem -Path "$($PSDriveName):\" -Recurse
    $UsedSize = $null
    foreach($item in $items)
    {    
        $UsedSize = $UsedSize + $item.Length
    }

    $PercentOutput = $UsedSize / $TotalDiskSizeInBytes * 100

    $ValueOutput = [string]::Format("{0:0.00} GB", $UsedSize / 1GB)
    $PercentOutputString = [string]::Format("{0:0.00} %", $PercentOutput)
    $MaxSize = [string]::Format("{0:0.00} GB", $TotalDiskSizeInBytes / 1GB)

    Write-Host "Genutzt : $ValueOutput, $PercentOutputString"
    Write-Host "Maximal : $MaxSize"

    Remove-PSDrive $PSDriveName
}
catch 
{    
    Write-Host "Error: $($PSItem.Exception.Message)"
    Write-Host  "Item: $($_.Exception.ItemName)"
}
finally
{
    Remove-PSDrive $PSDriveName -ErrorAction SilentlyContinue
}