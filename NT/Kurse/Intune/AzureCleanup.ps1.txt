<#
    Noch zu lösen
    Apple 
    Autopilot
    Corpotate Device identifiers
    Compliance Notification
    Device Config teils
    Client Apps
    Wipe Request
    Conditional Access
#>


#########################################################################################
Install-Module -Name AZ -Force
Install-Module -Name MSOnline -Force
Install-Module -Name AzureAD -Force
Install-Module -Name WindowsAutoPilotIntune -Force

$Cred = (Get-Credential -UserName Azureman@intunecenterde.onmicrosoft.com -Message "PW von AzureMan")


#########################################################################################
# Modul Az
Connect-AzureAD -Credential $Cred
Get-AzureADDevice | Remove-AzureADDevice
Get-AzureADGroup | Where-Object -Property DisplayName -NE "Intune-Users-MDM" | Remove-AzureADGroup

# Alte Methode, löscht eventuell den Service Admin
Get-AzureADUser | Where-Object -Property DisplayName -NE "T.Pham@ntsystems.de t.pham" | Where-Object -Property DisplayName -NE "AzureMan" | Remove-AzureADUser
<#
    Neue Methode, muss getestet werden
    Get-AzureADUser | `
    Where-Object -Property DisplayName -NotLike "*T*Pham*" | `
    Where-Object -Property DisplayName -NE "AzureMan" | `
    Where-Object -Property DisplayName -Like "*On-Premises Directory Synchronization Service Account*" | `
    Remove-AzureADUser
#>

#########################################################################################
# Modul MSOnline
Connect-MsolService -Credential $Cred
Get-MsolUser -ReturnDeletedUsers | Remove-MsolUser -RemoveFromRecycleBin -Force


#########################################################################################
# Modul Microsoft.Graph.Intune
Connect-MSGraph -Credential $Cred
Get-IntuneManagedDevice | Remove-IntuneManagedDevice 
Get-IntuneDeviceEnrollmentConfiguration | Where-Object -Property displayName -NE "All users and all devices" | Remove-IntuneDeviceEnrollmentConfiguration
Get-IntuneTermsAndConditions | Remove-IntuneTermsAndConditions
Get-IntuneDeviceCategory | Remove-IntuneDeviceCategory
Get-IntuneDeviceCompliancePolicy | Remove-IntuneDeviceCompliancePolicy
Get-IntuneDeviceConfigurationPolicy | Where-Object -Property Displayname -ne "Windows10-Custom-CommercialID" | Where-Object -Property Displayname -ne "Windows10-DefenderATP-Onboarding" | Remove-IntuneDeviceConfigurationPolicy
Get-IntuneAppProtectionPolicy | Remove-IntuneAppProtectionPolicy
Get-IntuneMobileAppConfigurationPolicy | Remove-IntuneMobileAppConfigurationPolicy


#########################################################################################
# Modul AzureAD und WindowsAutoPilotIntune
# Man braucht wahrscheinlich das Token von Connect-AzureAD -Credential $Cred
Get-AutoPilotDevice | Remove-AutoPilotDevice