<#
.SYNOPSIS
This script will provisioin a new shielded VM from existing disk template and a PDK file.
 
.DESCRIPTION
You will need a PDK and associated disk template file prior for shielded VM provisioning
 
.PARAMETER VMName
The name of the VM to be created
 
.PARAMETER PdkFile
The path for the pdk file
 
.PARAMETER TemplateDiskPath
The path for the disk template
 
.PARAMETER VMPath
The path for VM location.
 
#>
Param
(
    [Parameter (Mandatory=$true)][string] $VMName,
    [Parameter (Mandatory=$true)][string] $PdkFile,
    [Parameter (Mandatory=$true)][string] $TemplateDiskPath,
    [Parameter (Mandatory=$true)][string] $VMPath,
    [string] $switch = 'External',
    [Int64] $VMMemSize = 1GB
)
 
$VmVhdPath = $VMPath + '\' + $VMName + '.vhdx'
$fskFile = $VMPath + '\' + $VMName + '.fsk'
 
#check if the VMPath exist
#create the folder
If ((Test-Path $VMPath) -eq $false) 
{
    New-Item $VMPath -Type Directory
}
 
#create fsk file
New-ShieldedVMSpecializationDataFile -ShieldedVMSpecializationDataFilePath $fskfile -SpecializationDataPairs @{ '@ComputerName@' = "$VMName"; '@TimeZone@' = 'Pacific Standard Time' }
 
#Make a copy of the template
Copy-Item -Path $TemplateDiskPath -Destination $VmVhdPath
 
#create VM
$vm = New-VM -Name $VMName -Generation 2 -VHDPath $VmVhdPath -MemoryStartupBytes $VMMemSize -Path $VMPath -SwitchName $switch -erroraction Stop
 
$kp = Get-KeyProtectorFromShieldingDataFile -ShieldingDataFilePath $PdkFile
Set-VMkeyProtector -VM $vm -KeyProtector $kp
 
#Get PDK security policy
$importpdk = Invoke-CimMethod -ClassName  Msps_ProvisioningFileProcessor -Namespace root\msps -MethodName PopulateFromFile -Arguments @{FilePath=$PdkFile }
$cimvm = Get-CimInstance  -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "ElementName = '$VMName'"
 
$vsd = Get-CimAssociatedInstance -InputObject $cimvm -ResultClassName "Msvm_VirtualSystemSettingData"
$vmms = gcim -Namespace root\virtualization\v2 -ClassName Msvm_VirtualSystemManagementService
$ssd = Get-CimAssociatedInstance -InputObject $vsd -ResultClassName "Msvm_SecuritySettingData"
$ss = Get-CimAssociatedInstance -InputObject $cimvm -ResultClassName "Msvm_SecuritySErvice"
$cimSerializer = [Microsoft.Management.Infrastructure.Serialization.CimSerializer]::Create()
$ssdString = [System.Text.Encoding]::Unicode.GetString($cimSerializer.Serialize($ssd, [Microsoft.Management.Infrastructure.Serialization.InstanceSerializationOptions]::None))
$result = Invoke-CimMethod -InputObject $ss -MethodName SetSecurityPolicy -Arguments @{"SecuritySettingData"=$ssdString;"SecurityPolicy"=$importPdk.ProvisioningFile.PolicyData}
 
Enable-VMTPM -vm $vm
Initialize-ShieldedVM -VM $vm -ShieldingDataFilePath $PdkFile -ShieldedVMSpecializationDataFilePath $fskfile