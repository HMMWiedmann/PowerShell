$Path = 'C:\DSC\Part-test'
$ConfigPath = 'C:\DSC\Config'

Configuration Text1
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node $env:COMPUTERNAME
    {
        File Text1
        {
            Ensure          = "Present"
            DestinationPath = "$Path\text1.txt"
            Type            = 'File'
            Contents        = 'File1'
        }
    }    
}

Text1 -OutputPath "$ConfigPath\Text1"

Configuration Text2
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node $env:COMPUTERNAME
    {
        File Text2
        {
            Ensure          = "Present"
            DestinationPath = "$Path\text2.txt"
            Type            = 'File'
            Contents = 'File2'
        }       
    }
}

Text2 -OutputPath "$ConfigPath\Text2"

Configuration Text3
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node $env:COMPUTERNAME
    {
        File Text2
        {
            Ensure          = "Present"
            DestinationPath = "$Path\text3.txt"
            Type            = 'File'
            Contents = 'File3'
        }       
    }
}

Text3 -OutputPath "$ConfigPath\Text3"