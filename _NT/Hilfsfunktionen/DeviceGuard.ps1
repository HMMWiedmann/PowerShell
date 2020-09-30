function Create-DeviceGuardConfig 
{
    [CmdletBinding()]
    param 
    (
        # Path where the files will be saved
        [Parameter(Mandatory = $false)]
        [string] 
        $WorkingDirectory
    )
    
    begin 
    {
        if ($WorkingDirectory -eq $false) 
        {
            $WorkingDirectory = 'C:\DeviceGuard'
        }
    }
    
    process 
    {
        New-CIPolicy -Level FilePublisher `
             -Fallback Hash `
             -FilePath C:\Temp\CIPolicy\InitialCIPolicyAudit.xml `
             -UserPEs

        Set-RuleOption -FilePath C:\Temp\CIPolicy\InitialCIPolicy.xml `
                    -Option 3 `
                    -Delete

        New-CIPolicy -Audit `
                    -Level Hash `
                    -FilePath C:\Temp\CIPolicy\DelataCIPolicy.xml

        Merge-CIPolicy -PolicyPaths C:\Temp\CIPolicy\InitialCIPolicyAudit.xml, C:\temp\CIPolicy\DelataCIPolicy.xml `
                    -OutputFilePath C:\temp\CIPolicy\Delta_InitalialPolicy.xml

        Set-RuleOption -FilePath C:\temp\CIPolicy\Delta_InitalialPolicy.xml `
                    -Option 3 `
                    -Delete

        ConvertFrom-CIPolicy -XmlFilePath  C:\temp\CIPolicy\Delta_InitalialPolicy.xml `
                            -BinaryFilePath C:\temp\CIPolicy\Delta_InitalialPolicy.bin

    }
    
    end 
    {

    }
}

New-CIPolicy -Level FilePublisher `
             -Fallback Hash `
             -FilePath C:\Temp\CIPolicy\InitialCIPolicyAudit.xml `
             -UserPEs

Set-RuleOption -FilePath C:\Temp\CIPolicy\InitialCIPolicy.xml `
               -Option 3 `
               -Delete

New-CIPolicy -Audit `
             -Level Hash `
             -FilePath C:\Temp\CIPolicy\DelataCIPolicy.xml

Merge-CIPolicy -PolicyPaths C:\Temp\CIPolicy\InitialCIPolicyAudit.xml, C:\temp\CIPolicy\DelataCIPolicy.xml `
               -OutputFilePath C:\temp\CIPolicy\Delta_InitalialPolicy.xml

Set-RuleOption -FilePath C:\temp\CIPolicy\Delta_InitalialPolicy.xml `
               -Option 3 `
               -Delete

ConvertFrom-CIPolicy -XmlFilePath  C:\temp\CIPolicy\Delta_InitalialPolicy.xml `
                     -BinaryFilePath C:\temp\CIPolicy\Delta_InitalialPolicy.bin