$SQLBackupDir   = 'C:\SQL\Backup'
$SQLDBPath      = 'C:\SQL\DATA'
$SQLDBLogPath   = 'C:\SQL\LOG'

$SQLAdmins      = @("MAIL\UG-SQLMan", "MAIL\UG-DSCAdmins")

$LocalPWD = ConvertTo-SecureString "password" -AsPlainText -Force
$Engine = New-Object -TypeName System.Management.Automation.PSCredential ("mail\sqlengine$", $LocalPWD) 
$Agent =  New-Object -TypeName System.Management.Automation.PSCredential ("mail\sqlagent$", $LocalPWD) 

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
            SourcePath          = 'D:'
            SQLSysAdminAccounts = $SQLAdmins
            DependsOn           = '[WindowsFeature]NetFramework45'
            SQLCollation        = 'SQL_Latin1_General_CP1_CI_AS'
            AgtSvcAccount       = $agent
            SQLSvcAccount       = $Engine
            SQLUserDBDir        = $SQLDBPath
            SQLUserDBLogDir     = $SQLDBLogPath
            SQLTempDBDir        = $SQLDBPath
            SQLTempDBLogDir     = $SQLDBLogPath
            SQLBackupDir        = $SQLBackupDir
            SqlSvcStartupType   = 'Automatic'
        }
    }
}

SQLInstall -OutputPath "C:\DSC" -ConfigurationData $ConfigurationData
Start-DscConfiguration -Path "C:\DSC" -ComputerName $env:COMPUTERNAME -Wait -Verbose