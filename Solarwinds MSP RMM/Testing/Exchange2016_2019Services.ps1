# Services with StartupType
$ExServiceAutomatic = {

    "MSExchangeADTopology"
    "MSExchangeAntispamUpdate"
    "MSComplianceAudit"
    "MSExchangeCompliance"
    "MSExchangeDagMgmt"
    "MSExchangeDiagnostics"
    "MSExchangeEdgeSync"
    "MSExchangeFrontEndTransport"
    "MSExchangeHM"
    "MSExchangeHMRecovery"
    "MSExchangeIS"
    "MSExchangeMailboxAssistants"
    "MSExchangeMailboxReplication"
    "MSExchangeDelivery"
    "MSExchangeSubmission"
    "MSExchangeNotificationsBroker"
    "MSExchangeRepl"
    "MSExchangeRPC"
    "MSExchangeFastSearch"
    "Suchhost"
    "MSExchangeServiceHost"
    "MSExchangeThrottling"
    "MSExchangeTransport"
    "MSExchangeTransportLogSearch"
    "MSExchangeUM"
    "MSExchangeUMCR"
}

# Services with StartupType Manual
$ExServiceManual = {
    
    "MSExchangeIMAP4"
    "MSExchangeIMAP4BE"
    "MSExchangePOP3"
    "MSExchangePOP3BE"
    "WSBExchange"
}

foreach ($ExAutoService in $ExServiceAutomatic) 
{
    $StartupType = (Get-Service -Name $ExAutoService).StartupType
    if ($StartupType -ne "Automatic") {
        Set-Service -Name $ExAutoService -StartupType Automatic
    }
    if ($Status -ne "Running") 
    {
        Start-Service -Name $ExAutoService 
    }
    $StartupType = ""
}

foreach ($ExManuService in $ExServiceManual) 
{
    $StartupType = (Get-Service -Name $ExManuService).StartupType
    $Status = (Get-Service -Name $ExManuService).Status
    if ($StartupType -ne "Manual") {
        Set-Service -Name $ExManuService -StartupType Manual
    }
    $StartupType = ""
}