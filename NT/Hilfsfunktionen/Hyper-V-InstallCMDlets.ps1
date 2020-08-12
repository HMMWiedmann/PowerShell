# Server
# Install Hyper-V Manager and the PowerShell module (HVM only available on GUI systems)
Install-WindowsFeature -Name RSAT-Hyper-V-Tools
 
# Install the Hyper-V hypervisor and all tools (method #1)
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

# Client
# Install the Hyper-V management tool pack (Hyper-V Manager and the Hyper-V PowerShell module)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All -LimitAccess

# Install the entire Hyper-V stack (hypervisor, services, and tools)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All