<# Wird gebraucht bei Clients außerhalb einer Domäne
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "Server FQDN" -Force
#>

Get-ChildItem cert: -Recurse | where friendlyname -eq "DSC-OaaS Client Authentication" | Remove-Item -Verbose

$ServerName = 'VCCDSC-01'

$DSCServerURL = 'https://' + $ServerName + '.' + $env:USERDNSDOMAIN + ':4711/PSDSCPullServer.svc'
$RegistrationKey = Get-Content -Path '\\vccdsc-01.mail.cluster-center.de\c$\DSC\Database\Registration\RegistrationKeys.txt'

[DSCLocalConfigurationManager()]
Configuration PullClientConfig
{
    Node $env:COMPUTERNAME
    {
        Settings
        {
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyAndAutoCorrect'
        }

        ConfigurationRepositoryWeb SetPullClient
        {
            ServerURL = $DSCServerURL
            RegistrationKey = $RegistrationKey
            ConfigurationNames = $env:COMPUTERNAME
        }

        ReportServerWeb SetReportServer
        {
            ServerURL = $DSCServerURL
            RegistrationKey = $RegistrationKey
        }
    }
}

PullClientConfig -OutputPath "C:\DSC\PullclientSetup"
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path "C:\DSC\PullclientSetup" -Verbose -Force