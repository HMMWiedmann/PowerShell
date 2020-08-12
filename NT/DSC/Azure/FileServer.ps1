Configuration FileServer
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node IsFileServer
    {
        WindowsFeature FileServer
        {
            Ensure               = 'Present'
            Name                 = 'FS-FileServer'
        }
    }

    Node NotFileServer
    {
        WindowsFeature FileServer
        {
            Ensure               = 'Absent'
            Name                 = 'FS-FileServer'
        }
    }
}