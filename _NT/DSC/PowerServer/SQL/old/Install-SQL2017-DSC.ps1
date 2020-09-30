<# Argumente /ACTION="Install" 
            /INSTANCEID="DSCSrv" 
            /AGTSVCACCOUNT="mail\sqlagent$" 
            /SQLUS ERDBDIR="C:\SQL\DATA" 
            /AGTSVCSTARTUPTYPE="Automatic" 
            /QUIET="True" 
            /SQLTEMPDBLOGDIR="C:\SQL\LOG" 
            /SQLBACKUPDIR="C:\SQL\Backup" 
            /SQLSVCSTARTUPTYPE="Automatic" 
            /INSTANCENAME="DSCSRV" 
            /IACC EPTSQLSERVERLICENSETERMS="True" 
            /SQLUSERDBLOGDIR="C:\SQL\LOG" 
            /SQLSYSADMINACCOUNTS="MAIL\UG-DSCAdmins" "MAIL\UG-SQLMan" 
            /SQLTEMPDBDIR="C:\SQL\DATA" 
            /SQLCOLLATION="SQL_Latin1_General_CP1_ CI_AS" 
            /SQLSVCACCOUNT="mail\sqlengine$" 
            /FEATURES=SQLENGINE
#>

# Installieren von Powershellmodule für gMSA
$ADPowerhellState = (Get-WindowsFeature -Name RSAT-AD-Poweshell).Installed
if ($ADPowerhellState -eq $false) 
{
    Install-WindowsFeature -Name RSAT-AD-Poweshell
}

# Variabeln definieren
$gMSASQLEngine  = 'sqlengine$'
$gMSASQLAgent   = 'sqlagent$'
$SQLAdmins      = @("MAIL\UG-SQLMan", "MAIL\UG-DSCAdmins")
$SourcePath     = 'D:\'
$SQLBackupDir   = 'C:\SQL\Backup'
$SQLDBPath      = 'C:\SQL\DATA'
$SQLDBLogPath   = 'C:\SQL\LOG'

# Test der gMSA und gegebenenfalls installieren
$DomainController = Get-ADDomainController
$gMSAEngineObject = Get-ADServiceAccount -Identity $gMSASQLEngine -Server $DomainController
$gMSAAgentObject  = Get-ADServiceAccount -Identity $gMSASQLAgent -Server $DomainController
$SQLAgentState    = Test-ADServiceAccount -Identity $gMSAEngineObject.SamAccountName
$SQLEngineState   = Test-ADServiceAccount -Identity $gMSAAgentObject.SamAccountName

if ($SQLAgentState -ne $true)
{
    Install-ADServiceAccount -Identity $gMSASQLAgent   
}

if ($SQLEngineState -ne $true)
{
    Install-ADServiceAccount -Identity $gMSASQLEngine
}

# gMSA "Passwort"
$LocalPWD = ConvertTo-SecureString "password" -AsPlainText -Force
$SQLEngine   = New-Object -TypeName System.Management.Automation.PSCredential ("mail\sqlengine$", $LocalPWD) 
$SQLAgent    = New-Object -TypeName System.Management.Automation.PSCredential ("mail\sqlagent$", $LocalPWD) 

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = $env:COMPUTERNAME
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}

# DSC Config
Configuration SQLInstall
{
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    node $env:COMPUTERNAME
    {    
        WindowsFeature 'NetFramework45'
        {
            Name = 'Net-Framework-45-Core'
            Ensure = 'Present'
        }

        File DataDB
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $SQLDBPath
            Force           = $true
        }

        File LogDB
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $SQLDBLogPath
            Force           = $true
        }

        File Backup
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $SQLBackupDir
            Force           = $true
        }

        SqlSetup 'InstallInstance'
        {
            Action              = 'Install'
            InstanceName        = 'DSCSrv'
            InstanceID          = 'DSCSrv'   
            Features            = 'SQLENGINE'
            SourcePath          = $SourcePath
            SQLSysAdminAccounts = $SQLAdmins
            DependsOn           = '[WindowsFeature]NetFramework45'
            SQLCollation        = 'SQL_Latin1_General_CP1_CI_AS'
            AgtSvcAccount       = $SQLAgent
            SQLSvcAccount       = $SQLEngine
            SQLUserDBDir        = $SQLDBPath
            SQLUserDBLogDir     = $SQLDBLogPath
            SQLTempDBDir        = $SQLDBPath
            SQLTempDBLogDir     = $SQLDBLogPath
            SQLBackupDir        = $SQLBackupDir
            SqlSvcStartupType   = 'Automatic'
        }
    }
}

SQLInstall -OutputPath "C:\DSC\Local" -ConfigurationData $ConfigurationData
Start-DscConfiguration -Path "C:\DSC\Local" -ComputerName $env:COMPUTERNAME -Wait -Verbose 