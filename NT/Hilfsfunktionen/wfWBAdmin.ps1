Workflow wfWBAdmin
{
param(
    [parameter(Mandatory=$true)]
    [PSCredential] $Credentials,
    
    [parameter(Mandatory=$true)]
    [string[]] $ComputerName,

    [parameter(Mandatory=$true)]
    [string] $TargetPath,

    [parameter(Mandatory=$true)]
    [string] $LogPath
)
    $finished = $false
    $CurrentDate = Get-Date -Format yyyy.MM.dd

    parallel
    {
        while($finished -eq $false)
        {
            $CurrentTime = Get-Date -Format HH:mm:ss
            "$CurrentTime :   working"
            Start-Sleep -Seconds 15
        }

        sequence
        {
            foreach -parallel($computer in $ComputerName)
            {
                sequence
                {
                    "$computer :   Checking for feature 'Windows-Server-Backup' and installing if not already installed"
                    "Checking for feature 'Windows-Server-Backup' and installing if not already installed" | ` 
                    Out-File -FilePath "$LogPath\BackupLog-$CurrentDate-$computer.txt" -Append -NoClobber
                    
                    InlineScript
                    {
                        if((Get-WindowsFeature Windows-Server-Backup) -ne "Installed")
                        {
                            Install-WindowsFeature -Name Windows-Server-Backup
                        }
                    } -PSComputerName $computer -PSCredential $Credentials -PSAuthentication Negotiate | `
                    Out-File -FilePath "$LogPath\BackupLog-$CurrentDate-$computer.txt" -Append -NoClobber
                    
                    "$computer :   starting backup"
                    "starting backup" | Out-File -FilePath "$LogPath\BackupLog-$CurrentDate-$computer.txt" -Append -NoClobber
                    "" | Out-File -FilePath "$LogPath\BackupLog-$CurrentDate-$computer.txt" -Append -NoClobber
        
                    InlineScript
                    {
                        wbadmin start backup -backuptarget:$using:TargetPath -include:C: -allCritical -quiet
                    }  -PSComputerName $computer -PSCredential $Credentials -PSAuthentication Negotiate | `
                    Out-File -FilePath "$LogPath\BackupLog-$CurrentDate-$computer.txt" -Append -NoClobber
                    
                    "$computer :   workflow finished"
                    "workflow finished" | Out-File -FilePath "$LogPath\BackupLog-$CurrentDate-$computer.txt" -Append -NoClobber
                }
            }
            $workflow:finished = $true
        }
    }
}

#wfWBAdmin -Credentials (Get-Credential) -ComputerName "10.100.10.32","10.100.10.33" -TargetPath "B:" -LogPath C:\