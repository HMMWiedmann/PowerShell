function Setup-DSCWebPullServer
{
    <#
        Version 1.0 - 05.04.19  - UseExistingDB geändert in UseExistingSQLInstance
                                - Anpassung der SQL DB Pfade
    #>

    param
    (
        # Gibt den DSC Website Port an
        [Parameter(Mandatory=$true,Position=2)]
        [string]$WebsitePort,

        # Gibt an, ob eine SQL Datenbank verwendet werden soll
        [Parameter(Mandatory=$true)]
        [ValidateSet("True","False")]
        [string]$SQLProvider,

        # Gibt an, ob SQL installiert werden muss oder nicht
        [Parameter(Mandatory=$false)]
        [ValidateSet("True","False")]
        [string]$UseExistingSQLInstance,

        # Gibt den SQL ConnectionString an
        [Parameter(Mandatory=$false)]
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
        $ParameterAttribute.Position = 1

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
        #region DSC Pull Server Config
        $CertificateSubject    = $PsBoundParameters[$ParameterName]
        $CertificateThumbprint = ((Get-ChildItem -Path Cert:\LocalMachine\My).where{ $PSItem.Subject -eq $CertificateSubject }).Thumbprint
        $KeyGuid               = New-Guid
        $DSCServicePath        = 'C:\Program Files\WindowsPowerShell\DscService'
        $EndPointName          = 'PSDSCPullServer'
        $PullSrvConfig         = 'C:\DSC\PullSrvConfig'
        #endregion

        if($SQLProvider -eq "True")
        {
            #region SQL Config
            $SQLDBUSERDATA   = 'C:\SQL\USERDATA'
            $SQLDBUSERLOG    = 'C:\SQL\USERLOG'
            $SQLDBTEMPDATA   = 'C:\SQL\TEMPDATA'
            $SQLDBTEMPLOG    = 'C:\SQL\TEMPLOG'
            $SQLDBBACKUPDATA = 'C:\SQL\BACKUPDATA'
            $SQLSysAdmins    = @("XH2\T1-SQLAdmins", "XH2\T1-ServerAdmins", "NT AUTHORITY\SYSTEM")
            $SQLSourcePath   = 'D:'
            $SQLInstanceName = 'DSCSRV'
            $SQLDBName       = 'DSC'

            if (!$SQLConnectionString)
            {
                $SQLConnectionString = "Provider=SQLNCLI11;" + `
                                       "Integrated Security=SSPI;" + `
                                       "Persist Security Info=False;" + `
                                       "Initial Catalog=master;" + `
                                       "Data Source=$env:COMPUTERNAME\$SQLInstanceName;" + `
                                       "Database=$SQLDBName"
            }              
            #endregion

            #region Install SQL Service Accounts
            $SQLAgentName      = "SQLAgent"
            $SQLEngineName     = "SQLEngine"

            $State = (Get-WindowsFeature -Name RSAT-AD-Powershell).Installstate

            if ($State -ne "Installed")
            {
                Install-WindowsFeature -Name RSAT-AD-Powershell | Out-Null
                $SQLAgentState = Get-ADServiceAccount -Identity $SQLAgentName
                $SQLEngineState = Get-ADServiceAccount -Identity $SQLEngineName

                if ($SQLAgentState -eq "False") 
                {
                    Install-ADServiceAccount -Identity $SQLAgentName -Force
                }

                if ($SQLEngineState -eq "False") 
                {
                    Install-ADServiceAccount -Identity $SQLEngineName -Force
                }                
            }        
            #endregion

            #region SQL Service Accounts Credentials
            $LocalPWD  = ConvertTo-SecureString "password" -AsPlainText -Force # Vorläufiges Passwort für das SQLSetup
            $SQLEngine = New-Object -TypeName System.Management.Automation.PSCredential (($env:USERDOMAIN + "\" + $SQLAgentName + "$"), $LocalPWD) 
            $SQLAgent  = New-Object -TypeName System.Management.Automation.PSCredential (($env:USERDOMAIN + "\" + $SQLEngineName + "$"), $LocalPWD) 

            $ConfigurationData = @{
                AllNodes = @(
                    @{
                        NodeName                    = $env:COMPUTERNAME
                        PSDscAllowPlainTextPassword = $true
                        PSDscAllowDomainUser        = $true
                    }
                )
            }
            #endregion
        }
    }
    
    process
    {
        if($SQLProvider -eq "True")
        {
            if ($UseExistingSQLInstance -eq "True") 
            {
                Configuration SetupDSCPullServerWeb
                {
                    Import-DscResource -ModuleName PSDesiredStateConfiguration
                    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.2.0.0     
                    
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
        
                        xDscWebService 'PSDSCPullServer'
                        {
                            Ensure                   = 'Present' 
                            EndpointName             = $EndPointName
                            Port                     = $WebsitePort
                            UseSecurityBestPractices = $false
                            State                    = 'Started'
                            DependsOn                = '[File]RegistrationKeyFile'
                            CertificateThumbprint    = $CertificateThumbprint  
                            RegistrationKeyPath      = "$DSCServicePath\Registration\"
                            SqlProvider              = $true
                            SqlConnectionString      = $SQLConnectionString
                        }
                    }
                }
            }
            elseif($UseExistingSQLInstance -eq "False")
            {
                Configuration SetupDSCPullServerWeb
                {
                    Import-DscResource -ModuleName PSDesiredStateConfiguration
                    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.2.0.0
                    Import-DscResource -ModuleName SqlServerDsc           
                    
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
                            SourcePath          = $SQLSourcePath
                            SQLSysAdminAccounts = $SQLSysAdmins
                            DependsOn           = '[WindowsFeature]NetFramework45'
                            SQLCollation        = 'SQL_Latin1_General_CP1_CI_AS'
                            AgtSvcAccount       = $SQLAgent
                            SQLSvcAccount       = $SQLEngine
                            SQLUserDBDir        = $SQLDBUSERDATA
                            SQLUserDBLogDir     = $SQLDBUSERLOG
                            SQLTempDBDir        = $SQLDBTEMPDATA
                            SQLTempDBLogDir     = $SQLDBTEMPLOG
                            SQLBackupDir        = $SQLDBBACKUPDATA
                            SqlSvcStartupType   = 'Automatic'
                            AgtSvcStartupType   = 'Automatic'
                        }
        
                        xDscWebService PSDSCPullServer 
                        {
                            Ensure                   = 'Present' 
                            EndpointName             = $EndPointName
                            Port                     = $WebsitePort
                            UseSecurityBestPractices = $false
                            State                    = 'Started'
                            DependsOn                = '[File]RegistrationKeyFile'
                            CertificateThumbprint    = $CertificateThumbprint  
                            RegistrationKeyPath      = "$DSCServicePath\Registration\"
                            SqlProvider              = $true
                            SqlConnectionString      = $SQLConnectionString
                        }
                    }
                }
            }
        }
        elseif($SQLProvider -eq "False")
        {
            Configuration SetupDSCPullServerWeb
            {
                Import-DscResource -ModuleName PSDesiredStateConfiguration
                Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.2.0.0
                
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

                    xDscWebService 'PSDSCPullServer'
                    {
                        Ensure                   = 'Present' 
                        EndpointName             = $EndPointName
                        Port                     = $WebsitePort
                        UseSecurityBestPractices = $false
                        State                    = 'Started'
                        DependsOn                = '[File]RegistrationKeyFile'
                        CertificateThumbprint    = $CertificateThumbprint  
                        RegistrationKeyPath      = "$DSCServicePath\Registration\"
                    }                    
                }
            }
        }

        SetupDSCPullServerWeb -OutputPath $PullSrvConfig -ConfigurationData $ConfigurationData
        Start-DscConfiguration -Path $PullSrvConfig -Wait -Force
    }
    
    end
    {
        $DSCServerURL = "https://" + $env:COMPUTERNAME + '.' + $env:USERDNSDOMAIN + ':' + $WebsitePort + '/' + $EndPointName + '.svc'

        $WebsiteResult = Invoke-WebRequest -UseBasicParsing -Uri $DSCServerURL
        if($WebsiteResult.StatusCode -eq 200)
        {
            Write-Host ""
            Write-Host "Website is working"
            Write-Host ""            
            Write-Host "Pull Server URL:                $DSCServerURL"
            Write-Host "" 
            Write-Host "Pull Server RegistrationKey:    $KeyGuid"
        }
        else
        {
            Write-Host ""
            Write-Host "Website is not working"
        }
    }
}