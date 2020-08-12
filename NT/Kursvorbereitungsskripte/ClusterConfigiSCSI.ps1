$Comps = "NODE-B", "NODE-D","NODE-Z"
Invoke-Command -ComputerName $Comps -ScriptBlock { 

    Enable-MSDSMAutomaticClaim -BusType iSCSI
    Restart-Computer -Force
}

Invoke-Command -ComputerName $Comps -ScriptBlock { hostname }

Invoke-Command -ComputerName $Comps -ScriptBlock { 

    Start-Service -Name MSiSCSI
    Set-Service -Name MSiSCSI -StartupType Automatic
}

Invoke-Command -ComputerName $Comps -ScriptBlock { 

    New-IscsiTargetPortal -TargetPortalAddress 192.168.140.100
    Get-IscsiTarget | Connect-IscsiTarget -IsMultipathEnabled $true -IsPersistent $true
}