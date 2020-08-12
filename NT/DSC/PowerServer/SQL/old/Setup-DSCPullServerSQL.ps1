function Setup-DSCWebPullServer
{
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = "Default")]
        [string]$FirewallPort,

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [switch]$SQLProvider,

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [string]$SQLConnectionString
    )   

    dynamicParam
    {
        # Set the dynamic parameters' name
        $ParameterName = 'CertificateSubject'
            
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = "Default"

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = (Get-ChildItem -Path Cert:\LocalMachine\My).Subject
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    begin
    {
        $CertificateSubject = $PsBoundParameters[$ParameterName]
        $KeyGuid = New-Guid
        $DSCServicePath = "C:\DSC\DSCService"
        $EndPointName = "PSDSCPullServer"
    
        $CertificateThumbprint = ((Get-ChildItem -Path Cert:\LocalMachine\My).where{ $PSItem.Subject -eq $CertificateSubject }).Thumbprint

        # Passwort speicher in MOF für gMSA erlauben
        if($SQLProvider -eq $true)
        {
            $ConfigurationData = @{
                AllNodes = @(
                    @{
                        NodeName = $env:COMPUTERNAME
                        PSDscAllowPlainTextPassword = $true
                        PSDscAllowDomainUser = $true
                    }
                )
            }

            $SQLInstanceName = 'DSCSrv'

            # Installieren von Powershellmodule für gMSA
            $ADPowerhellState = (Get-WindowsFeature -Name RSAT-AD-Poweshell).Installed
            if ($ADPowerhellState -eq $false) 
            {
                Install-WindowsFeature -Name RSAT-AD-Poweshell
            }

            # Variabeln definieren
            $gMSASQLEngine = 'sqlengine$'
            $gMSASQLAgent = 'sqlagent$'
            $SQLAdmins      = @("MAIL\UG-SQLMan", "MAIL\UG-DSCAdmins")
            $SourcePath = 'D:\'
            $SQLBackupDir   = 'C:\SQL\Backup'
            $SQLDBPath      = 'C:\SQL\DATA'
            $SQLDBLogPath   = 'C:\SQL\LOG'

            # Test der gMSA und gegebenenfalls installieren
            $DomainController = Get-ADDomainController
            $gMSAEngineObject = Get-ADServiceAccount -Identity $gMSASQLEngine -Server $DomainController
            $gMSAAgentObject = Get-ADServiceAccount -Identity $gMSASQLAgent -Server $DomainController
            $SQLAgentState = Test-ADServiceAccount -Identity $gMSAEngineObject.SamAccountName
            $SQLEngineState = Test-ADServiceAccount -Identity $gMSAAgentObject.SamAccountName

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
            $SQLEngine = New-Object -TypeName System.Management.Automation.PSCredential ("mail\sqlengine$", $LocalPWD) 
            $SQLAgent =  New-Object -TypeName System.Management.Automation.PSCredential ("mail\sqlagent$", $LocalPWD)
        }
    }
    
    process
    {
        Configuration PullServerWEB
        {
            Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
            Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion 8.2.0.0

            if($SQLProvider -eq $true)
            {
                Import-DscResource -ModuleName 'SqlServerDsc'
            }

            Node $env:COMPUTERNAME
            {
                WindowsFeature 'IIS'
                {
                    Ensure = 'Present'
                    Name = 'Web-Server'
                } 

                WindowsFeature 'DSCServiceFeature'
                { 
                    Ensure = 'Present'
                    Name   = 'DSC-Service'    
                }

                WindowsFeature 'WebConsole'
                {
                    Ensure = 'Present'
                    Name = 'Web-Mgmt-Console'
                }
                    
                File 'RegistrationKeyFile'
                {
                    Ensure = 'Present'
                    Type = 'File'
                    DestinationPath = "$DSCServicePath\Registration\RegistrationKeys.txt"
                    Contents = $KeyGuid.Guid
                } 

                if($SQLProvider -eq $true)
                {
                    WindowsFeature 'NetFramework45'
                    {
                        Name = 'Net-Framework-45-Core'
                        Ensure = 'Present'
                    }

                    File 'DataDB'
                    {
                        Ensure          = 'Present'
                        Type            = 'Directory'
                        DestinationPath = $SQLDBPath
                        Force           = $true
                    }

                    File 'LogDB'
                    {
                        Ensure          = 'Present'
                        Type            = 'Directory'
                        DestinationPath = $SQLDBLogPath
                        Force           = $true
                    }

                    File 'Backup'
                    {
                        Ensure          = 'Present'
                        Type            = 'Directory'
                        DestinationPath = $SQLBackupDir
                        Force           = $true
                    }

                    SqlSetup 'InstallInstance'
                    {
                        Action              = 'Install'
                        InstanceName        = $SQLInstanceName
                        InstanceID          = $SQLInstanceName   
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
                        AgtSvcStartupType   = 'Automatic'
                        SecurityMode        = 'Windows'
                    }

                    xDscWebService 'PSDSCPullServerSQL '
                    {             
                        Ensure                   = 'Present' 
                        EndpointName             = $EndPointName
                        Port                     = $FirewallPort
                        CertificateThumbprint    = $CertificateThumbprint
                        State                    = 'Started'
                        DependsOn                = '[File]RegistrationKeyFile'
                        UseSecurityBestPractices = $false
                        RegistrationKeyPath      = "$DSCServicePath\Registration\"
                        DatabasePath             = "$DSCServicePath\Database\"
                        PhysicalPath             = "$DSCServicePath\Website\$EndPointName\"
                        ModulePath               = "$DSCServicePath\Modules\"
                        ConfigurationPath        = "$DSCServicePath\Configuration\"
                        SqlProvider              = $SQLProvider
                        SqlConnectionString      = $SQLConnectionString
                    }
                }
                else
                {
                    xDscWebService 'PSDSCPullServer'
                    {             
                        Ensure                   = 'Present' 
                        EndpointName             = $EndPointName
                        Port                     = $FirewallPort
                        CertificateThumbprint    = $CertificateThumbprint
                        State                    = 'Started'
                        DependsOn                = '[File]RegistrationKeyFile'  
                        UseSecurityBestPractices = $false
                        RegistrationKeyPath      = "$DSCServicePath\Registration\"
                        DatabasePath             = "$DSCServicePath\Database\"
                        PhysicalPath             = "$DSCServicePath\Website\$EndPointName\"
                        ModulePath               = "$DSCServicePath\Modules\"
                        ConfigurationPath        = "$DSCServicePath\Configuration\"
                    }
                }
            }
        }
    }
    
    end
    {
        if($SQLProvider -eq $true)
        {
            PullServerWeb -OutputPath "$DSCServicePath\PullserverSetup" -ConfigurationData $ConfigurationData
        }
        else
        {
            PullServerWEB -OutputPath "$DSCServicePath\PullserverSetup"
        }        

        Start-DscConfiguration -Path "$DSCServicePath\PullserverSetup" -Verbose -Wait -Force
    
        $ServerURL = "DSC Server URL: https://" + $env:COMPUTERNAME + '.' + $env:USERDNSDOMAIN + ':' + $FirewallPort + '/' + $EndPointName + '.svc'
        Write-Host ""
        Write-Host $ServerURL

        if($SQLProvider -eq $true)
        {
            Write-Host "Using SQL Database: $($env:COMPUTERNAME)/$($SQLInstanceName)"
        }
    }
}