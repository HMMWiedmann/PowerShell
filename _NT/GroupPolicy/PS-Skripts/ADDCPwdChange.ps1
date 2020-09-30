<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-ADDCPwdChange
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [switch]
        $RWDCs,

        # Param2 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [switch]
        $RODCs
    )

    Begin
    {
    $listRWDCs = (Get-ADDomain).ReplicaDirectoryServers

    if ($RODCs -ne $null) {
                              $listRODCs = (Get-ADDomain).ReadOnlyReplicaDirectoryServers
                           }
    else {}
    $DCOU = (Get-ADDomain).DomainControllersContainer
    $PDCE = (Get-ADDomain).PDCEmulator
    }
    Process
    {

    foreach ($DC in $listRWDCs) {
                                    Get-ADComputer -Filter { dnshostname -eq $DC } -Properties pwdlastset -SearchBase $DCOU -Server $PDCE | Select-Object @{n="RWDC"; e={"[X]"} }, name, @{n="last password change"; e={[DateTime]::FromFileTime($PSItem.pwdlastset)}}, @{n="delta days"; e={(New-TimeSpan -Start ([DateTime]::FromFileTime($PSItem.pwdlastset)) -End (Get-Date)).Days }}
                                }
    
    if ($listRODCs -ne $null) {
                                foreach ($DC in $listRODCs) {
                                                                Get-ADComputer -Filter { dnshostname -eq $DC } -Properties pwdlastset -SearchBase $DCOU -Server $PDCE | Select-Object @{n="RODC"; e={"[X]"} }, name, @{n="last password change"; e={[DateTime]::FromFileTime($PSItem.pwdlastset)}}, @{n="delta days"; e={(New-TimeSpan -Start ([DateTime]::FromFileTime($PSItem.pwdlastset)) -End (Get-Date)).Days }}
                                                            }
                              }
    }
    End
    {
    }
}