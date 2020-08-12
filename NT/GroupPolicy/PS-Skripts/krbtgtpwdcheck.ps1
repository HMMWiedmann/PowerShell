<#
.Synopsis
   Checks krbtgt password version
.DESCRIPTION
   Checks krbtgt password version on every RWDC
.EXAMPLE
   Check-krbtgtpwd
.NOTES
   Version 1.0.0 - 09/08/2017 - Martin Handl - initial
#>
function Check-krbtgtpwd
{
    [CmdletBinding()]
    Param
    ()

    Begin
    {
    }
    Process
    {
    $RWDCs = (Get-ADDomain).ReplicaDirectoryServers.where{ $PSItem -notlike $(Get-ADDomain).PDCEmulator }
    $DomainDN=(Get-ADDomain).DistinguishedName
    $PDCEVersion = (Get-ADReplicationAttributeMetadata `
                        -Object "CN=krbtgt,CN=users,$DomainDN" `
                        -Server (Get-ADDomain).PDCEmulator `
                        -Properties dBCSPwd).Version
    foreach ($DC in $RWDCs)
    {
        $PwdVersion = (Get-ADReplicationAttributeMetadata `
                        -Object "CN=krbtgt,CN=users,$DomainDN" `
                        -Server $DC `
                        -Properties dBCSPwd).Version
        if ($PwdVersion -ne $PDCEVersion)
        {
        Write-Host -ForegroundColor Red -BackgroundColor Black "WARNING: PDC-E's krbtgt has version $PDCEVersion - DC's krbtgt $DC has version $PwdVersion! `nInvestigate $DC!"
        } else {
        Write-Verbose "DC $DC has krbtgt password version $PwdVersion - same as PDC-E"
        }
    }
    }
    End
    {
    }
}
