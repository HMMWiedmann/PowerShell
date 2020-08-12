function Setup-DSCWebPullServer
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$FirewallPort,

        [Parameter(Mandatory = $false)]
        [boolean]$SQLProvider,

        [Parameter(Mandatory = $false)]
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
        $CertificateSubject = $PsBoundParameters[$ParameterName]
        $KeyGuid = New-Guid
        $DatabasePath = "C:\DSC\Database"
    
        $CertificateThumbprint = ((Get-ChildItem -Path Cert:\LocalMachine\My).where{ $PSItem.Subject -eq $CertificateSubject }).Thumbprint
    }
    
    process
    {
        Configuration PullServerWEB
        {
            Import-DscResource -ModuleName PSDesiredStateConfiguration
            Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.2.0.0

            Node $env:COMPUTERNAME
            {
                WindowsFeature IIS
                {
                    Ensure = 'Present'
                    Name = 'Web-Server'
                } 

                WindowsFeature DSCServiceFeature 
                { 
                    Ensure = 'Present'
                    Name   = 'DSC-Service'    
                }

                WindowsFeature WebConsole
                {
                    Ensure = 'Present'
                    Name = 'Web-Mgmt-Console'
                }
                    
                File RegistrationKeyFile
                {
                    Ensure = 'Present'
                    Type = 'File'
                    DestinationPath = "C:\Program Files\WindowsPowerShell\DscService\RegistrationKey.txt"
                    Contents = $KeyGuid.Guid
                } 

                if($SQLProvider -eq $true)
                {
                    xDscWebService PSDSCPullServer 
                    {             
                        Ensure                   = 'Present' 
                        EndpointName             = 'PSDSCPullServer'
                        Port                     = $FirewallPort
                        PhysicalPath             = "C:\DSC\Website\PSDSCPullServer"
                        CertificateThumbprint    = $CertificateThumbprint
                        State                    = 'Started'
                        DependsOn                = '[File]RegistrationKeyFile'  
                        UseSecurityBestPractices = $false
                        RegistrationKeyPath      = "C:\Program Files\WindowsPowerShell\DscService\RegistrationKey.txt"
                        SqlProvider              = $SQLProvider
                        SqlConnectionString      = $SQLConnectionString
                    }
                }
                else
                {
                    xDscWebService PSDSCPullServerSQL
                    {             
                        Ensure                   = 'Present' 
                        EndpointName             = 'PSDSCPullServer'
                        Port                     = $FirewallPort
                        PhysicalPath             = "C:\DSC\Website\PSDSCPullServer"
                        CertificateThumbprint    = $CertificateThumbprint
                        State                    = 'Started'
                        DependsOn                = '[File]RegistrationKeyFile'  
                        UseSecurityBestPractices = $true
                        RegistrationKeyPath      = "C:\Program Files\WindowsPowerShell\DscService\RegistrationKey.txt"
                    }
                }
            }
        }
    }
    
    end
    {
        PullServerWEB -OutputPath "$DatabasePath\PullserverSetup"
        Start-DscConfiguration -Path "$DatabasePath\PullserverSetup" -Verbose -Wait -Force
    
        $ServerURL = (Get-DscConfiguration).DSCServerURL
        Write-Host "DSC Server URL: $ServerURL"
    }
}