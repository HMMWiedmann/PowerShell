function Single-DynamicParam 
{
    [CmdletBinding()]
    Param
    (

    )

    dynamicParam
    {
        # Set the dynamic parameters' name
        $ParameterName = 'dyn1'
            
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
        $arrSet = (Get-NetAdapter).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    begin 
    {
        # Bind the parameter to a friendly variable
        $dyn1 = $PsBoundParameters[$ParameterName]
    }

    process 
    {
        # Your code goes here
        "dyn1"
        $dyn1
    }
}

function Double-DynamicParam 
{
    [CmdletBinding()]
    Param
    (

    )
 
    DynamicParam 
    {
        # Set the dynamic parameters' name
        $ParameterName = 'dyn1'
        $ParameterName2 = 'dyn2'
            
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection2 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        $ParameterAttribute2 = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute2.Mandatory = $true
        $ParameterAttribute2.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)
        $AttributeCollection2.Add($ParameterAttribute2)

        # Generate and set the ValidateSet 
        $arrSet = (Get-NetAdapter).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        $arrSet2 = (Get-NetAdapter).Name
        $ValidateSetAttribute2 = New-Object System.Management.Automation.ValidateSetAttribute($arrSet2)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)
        $AttributeCollection2.Add($ValidateSetAttribute2)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $RuntimeParameter2 = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName2, [string], $AttributeCollection2)
        $RuntimeParameterDictionary.Add($ParameterName2, $RuntimeParameter2)

        return $RuntimeParameterDictionary
    }

    begin 
    {
        # Bind the parameter to a friendly variable
        $dyn1 = $PsBoundParameters[$ParameterName]
        $dyn2 = $PsBoundParameters[$ParameterName2]
    }

    process 
    {
        # Your code goes here
        "dyn1"
        Get-ChildItem -Path $dyn1

        "dyn2"
        Get-ChildItem -Path $dyn2 
    }
}