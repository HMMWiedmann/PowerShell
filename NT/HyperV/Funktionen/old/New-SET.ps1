<#
    .SYNOPSIS
        Creates a new Virtual Switch using embedded Teaming

    .DESCRIPTION
        Uses NIC1 and NIC2 to create a new Virtual Switch for VMs.
        The HyperV Host will get an Virtual Networkadapter

    .PARAMETER SwitchName
        Name of Virtual Switch

    .PARAMETER PhysicalNICs
        Name of physical Netadapters

    .EXAMPLE
        New-SET -SwitchName SET -PhysicalNICs Datacenter-1, Datacenter-2
    
    .EXAMPLE
        New-SET -PhysicalNICs Datacenter-1, Datacenter-2 -SwitchName EXTERNAL -HostVNICName VDatacenter-1

    .NOTES
        By Moritz Wiedmann
#>
function New-SET
{
    param 
    (
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$SwitchName,

        [Parameter(Mandatory=$false, Position = 3)]
        [string]$HostVNICName
    )

    dynamicParam
    {
        # Set the dynamic parameters' name
        $ParameterName = 'PhysicalNICs'
            
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = (Get-NetAdapter -Physical).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    Begin
    {
        # Bind the parameter to a friendly variable
        $PhysicalNICs = $PsBoundParameters[$ParameterName]

        Import-Module -Name Hyper-V
    }

    Process
    {
        $NetAdapters= $PhysicalNICs.foreach{ (Get-NetAdapter -Name $PSItem).Name }

        New-VMSwitch -Name $SwitchName -NetAdapterName $NetAdapters -AllowManagementOS $false 
        Add-VMNetworkAdapter -ManagementOS -SwitchName $SwitchName -Name $HostVNICName
        # Set-VMNetworkAdapterTeamMapping -VMNetworkAdapterName $HostVNICName -ManagementOS -PhysicalNetAdapterName $NIC1
    }

    End 
    {}
}