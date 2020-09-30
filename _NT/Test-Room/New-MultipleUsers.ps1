function New-MultipleUsers
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet("SCCM","PowerServer","WIN10")]
        $Kurs,

        [Parameter(Mandatory=$true)]
        [System.Array]$Teilnehmerplaetze
    )
    
    begin 
    {
        $DomainPath = (Get-ADDomain).DistinguishedName
        $UsersOU = "OU=$Kurs," + $DomainPath
        $PDCEmulator = (Get-ADDomain).PDCEmulator

        $PWD = ConvertTo-SecureString -String "C0mplex" -AsPlainText -Force
    }
    
    process 
    {
        New-ADOrganizationalUnit -Name $Kurs -Path $DomainPath -ProtectedFromAccidentalDeletion $false -Server $PDCEmulator

        foreach($Platz in $Teilnehmerplaetze)
        { 
            New-ADOrganizationalUnit -Name $Platz -Path $UsersOU -ProtectedFromAccidentalDeletion $false -Server $PDCEmulator
        }

        $AllOUs = Get-ADOrganizationalUnit -Filter { name -like "*" }

        $selectedOU = ($AllOUs.where{ $PSItem.DistinguishedName -match ',' + $UsersOU }).DistinguishedName

        $selectedOU.ForEach{ 
            New-ADOrganizationalUnit -Name Computer -Path $PSItem -ProtectedFromAccidentalDeletion $false -Server $PDCEmulator
            New-ADOrganizationalUnit -Name User -Path $PSItem -ProtectedFromAccidentalDeletion $false -Server $PDCEmulator
        }

        foreach($Platz in $Teilnehmerplatze)
        {
            $OUPath = $selectedOU | Where-Object -Property Name -Like $PSItem

            New-ADUser -AccountPassword $PWD -CannotChangePassword $false -DisplayName "$($Platz)-User01" -Enabled $true -Name "$($Platz)-User01" -Path $OUPath
            New-ADUser -AccountPassword $PWD -CannotChangePassword $false -DisplayName "$($Platz)-User02" -Enabled $true -Name "$($Platz)-User02" -Path $OUPath
            New-ADUser -AccountPassword $PWD -CannotChangePassword $false -DisplayName "$($Platz)-User03" -Enabled $true -Name "$($Platz)-User03" -Path $OUPath

        }
    }
    
    end 
    {

    }
}