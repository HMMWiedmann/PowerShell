$KeyGuid = New-Guid

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
            DestinationPath = "C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents = $KeyGuid.Guid
        } 

        xDscWebService PSDSCPullServer 
        {             
            Ensure                   = 'Present' 
            EndpointName             = 'PSDSCPullServer'
            Port                     = '4711'
            PhysicalPath             = "C:\DSC\Website\PSDSCPullServer"
            CertificateThumbprint    = '67FD901196934A90C6E2F67AB9F7A1F57EFEDA2F'
            State                    = 'Started'
            DependsOn                = '[File]RegistrationKeyFile'  
            UseSecurityBestPractices = $false
            RegistrationKeyPath      = "C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt"
            SqlProvider              = $true
            SqlConnectionString      = 'Provider=SQLNCLI11;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=master;Data Source=VCCDSC-01\DSCPULLSERVER;Database=DSC'
        }        
    }
}

PullServerWEB -OutputPath "C:\DSC\Config\PullserverSetup"
Start-DscConfiguration -Path "C:\DSC\Config\PullserverSetup" -Verbose -Wait -Force