$DC1 = Get-ADGroupMember -Identity "Domain Controllers"
$DC2 = (Get-ADComputer -Filter * -Properties *).where{ $PSItem.primaryGroupID -eq "516" }
Get-ADDomainController -Filter *