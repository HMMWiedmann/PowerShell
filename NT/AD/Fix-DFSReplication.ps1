$domain = (Get-ADDomain -Current LoggedOnUser).DistinguishedName
$pdc = (Get-ADDomain).PDCEmulator

$dcs = Get-ADObject -Filter {(objectclass -eq "computer")} `
-SearchBase "OU=Domain Controllers,$domain"`
-Properties Name | Sort-Object name

$dcs | ForEach-Object{
$dc = $PSItem.Name

    Invoke-Command -ComputerName $dc -ScriptBlock{

        $domain = (Get-ADDomain -Current LoggedOnUser).DistinguishedName
        $dc = hostname
        $pdc = (Get-ADDomain).PDCEmulator
        $sysvolADObject = Get-ADObject -Filter {(objectclass -eq "msDFSR-Subscription")} `
        -SearchBase "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$dc,OU=Domain Controllers,$domain"`
        -Properties "msDFSR-Options","msDFSR-Enabled"

        Write-Host -ForegroundColor Yellow -BackgroundColor Black "Current Host: $dc"

        Write-Host -ForegroundColor Black -BackgroundColor Cyan "Restarting NLA Service to correct Network Profile"
        Restart-Service NlaSvc -Force

        Write-Host -ForegroundColor Black -BackgroundColor Cyan "Installing DFSR Management Tools"
        Install-WindowsFeature -Name RSAT-DFS-Mgmt-Con 


        if($pdc.Contains($dc))
        {
            Write-Host -ForegroundColor Black -BackgroundColor Cyan "Setting msDFSR-Options to 1"
            Set-ADObject -Identity $sysvolADObject.DistinguishedName -Replace @{"msDFSR-Options" = 1}
        }

        Write-Host -ForegroundColor Black -BackgroundColor Cyan "Setting msDFSR-Enabled to false"
        Set-ADObject -Identity $sysvolADObject.DistinguishedName -Replace @{"msDFSR-Enabled" = $false}
    }
}

Write-Host -ForegroundColor Black -BackgroundColor Cyan "Forcing AD Replication"
repadmin /syncall /P /e
Start-Sleep(10)

Invoke-Command -ComputerName $pdc -ScriptBlock{


    $domain = (Get-ADDomain -Current LoggedOnUser).DistinguishedName
    $dc = hostname
    $pdc = (Get-ADDomain).PDCEmulator
    $sysvolADObject = Get-ADObject -Filter {(objectclass -eq "msDFSR-Subscription")} `
    -SearchBase "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$dc,OU=Domain Controllers,$domain"`
    -Properties "msDFSR-Options","msDFSR-Enabled"

    Write-Host -ForegroundColor Yellow -BackgroundColor Black "Current Host: $dc"
    
    Write-Host -ForegroundColor Black -BackgroundColor Cyan "Restarting DFSR Service"
    Restart-Service DFSR 
    Start-Sleep(20)
    
    Write-Host -ForegroundColor Black -BackgroundColor Cyan "Setting msDFSR-Enabled to true"
    Set-ADObject -Identity $sysvolADObject.DistinguishedName -Replace @{"msDFSR-Enabled" = $true}
    
    Write-Host -ForegroundColor Black -BackgroundColor Cyan "Forcing AD Replication"
    repadmin /syncall /P /e
    Start-Sleep(10)

    Write-Host -ForegroundColor Black -BackgroundColor Cyan "Executing DFSRDIAG"
    dfsrdiag pollad
}

$dcs | ForEach-Object{

    $dc = $PSItem.Name

    Invoke-Command -ComputerName $dc -ScriptBlock{
        $domain = (Get-ADDomain -Current LoggedOnUser).DistinguishedName
        $dc = hostname
        $pdc = (Get-ADDomain).PDCEmulator
        $sysvolADObject = Get-ADObject -Filter {(objectclass -eq "msDFSR-Subscription")} `
        -SearchBase "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$dc,OU=Domain Controllers,$domain"`
        -Properties "msDFSR-Options","msDFSR-Enabled"

        if(!$pdc.Contains($dc))
        {
            Write-Host -ForegroundColor Yellow -BackgroundColor Black "Current Host: $dc"
            Write-Host -ForegroundColor Black -BackgroundColor Cyan "Restarting DFSR Service"
            Restart-Service DFSR 
            Start-Sleep(20)

            Write-Host -ForegroundColor Black -BackgroundColor Cyan "Setting msDFSR-Enabled to true"
            Set-ADObject -Identity $sysvolADObject.DistinguishedName -Replace @{"msDFSR-Enabled" = $true}

            Write-Host -ForegroundColor Black -BackgroundColor Cyan "Executing DFSRDIAG"
            dfsrdiag pollad  
        }        
    }
}