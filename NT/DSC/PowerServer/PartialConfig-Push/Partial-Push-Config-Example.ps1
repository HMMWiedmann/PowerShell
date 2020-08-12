# Schritt 1: LCM Config Erstellen (LCM-Part.ps1)
# Schritt 2: LCM Config setzen
# Schritt 3: partial config erstellen
# Schritt 4: DSC partial config an den Client Pushen
# Schritt 5: DSC partial config anwenden

# Variabeln setzen
$ConfigPath = "$($env:SystemDrive)\DSC\Config"
$LCMConfigPath = "$($env:SystemDrive)\DSC\LCMConfig"

# Schritt 1
New-LCMPartPushConfig -LCMConfigPath $LCMConfigPath

# Schritt 2
Set-DscLocalConfigurationManager -Path $LCMConfigPath -Verbose -Force

# Schritt 3
New-PartConfig -ConfigPath $ConfigPath

# Schritt 4
Publish-DscConfiguration -Path "$ConfigPath\Text1" -ComputerName $env:COMPUTERNAME -Verbose
Publish-DscConfiguration -Path "$ConfigPath\Text2" -ComputerName $env:COMPUTERNAME -Verbose
Publish-DscConfiguration -Path "$ConfigPath\Text3" -ComputerName $env:COMPUTERNAME -Verbose

# Schritt 5
Start-DscConfiguration -UseExisting -Verbose -Wait

# LCM Config
function New-LCMPartPushConfig
{
    [CmdletBinding()]
    param 
    (
        # Path to LCM Config
        [Parameter(Mandatory = $true)]
        [string]
        $LCMConfigPath
    )

    [DscLocalConfigurationManager()]
    Configuration PushPartialConfig
    {
        Node $env:COMPUTERNAME
        {
            Settings
            {
                ConfigurationMode = 'ApplyAndAutoCorrect'
                RebootNodeIfNeeded = $true
            }
    
            PartialConfiguration Text1
            {
                RefreshMode = 'Push'
            }
    
            PartialConfiguration Text2
            {
                RefreshMode = 'Push'
            }
    
            PartialConfiguration Text3
            {
                RefreshMode = 'Push'
            }
        }
    }
    
    PushPartialConfig -OutputPath $LCMConfigPath
}

# Config
function New-PartConfig
{
    param
    (
        # Path where the Config Files will be safed
        [Parameter(Mandatory = $true)]
        [String]
        $ConfigPath
    )
    $DestinationPath = 'C:\DSC\Part-test'

    Configuration Text1
    {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        node $env:COMPUTERNAME
        {
            File Text1
            {
                Ensure          = "Present"
                DestinationPath = "$DestinationPath\text1.txt"
                Type            = 'File'
                Contents        = 'File1'
            }       
        }    
    }
    Text1 -OutputPath "$ConfigPath\Text1"

    Configuration Text2
    {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        node $env:COMPUTERNAME
        {
            File Text2
            {
                Ensure          = "Present"
                DestinationPath = "$DestinationPath\text2.txt"
                Type            = 'File'
                Contents = 'File2'
            }       
        }
    }
    Text2 -OutputPath "$ConfigPath\Text2"

    Configuration Text3
    {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        node $env:COMPUTERNAME
        {
            File Text2
            {
                Ensure          = "Present"
                DestinationPath = "$DestinationPath\text3.txt"
                Type            = 'File'
                Contents = 'File3'
            }       
        }
    }
    Text3 -OutputPath "$ConfigPath\Text3"
}