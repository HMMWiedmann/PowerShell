function Set-PageFileInfo 
{
    <#
        .SYNOPSIS
            Configure the PageFile location/drive, initialsize and maximumsize.
        .DESCRIPTION
            IMPORTANT: 
                - The AutomaticManagedPagefile property determines whether the system managed pagefile is enabled. 
                - This capability is not available on windows server 2003,XP and lower versions.
                - Only if it is NOT managed by the system and will also allow you to change these.
        .NOTES
            Author: Robin Hermann
        .LINK
            http://wiki.webperfect.ch
        .EXAMPLE
            Set-PageFileSize -DriveLetter <DriveLetter> -InitialSize <InitialSize> -MaximumSize <MaximumSize>
            Configure the PageFile location/drive, initialsize and maximumsize.
    #>

    [CmdletBinding()]
    Param(
            [Parameter(Mandatory)]
            [ValidatePattern('^[A-Z]$')]
            [String]$DriveLetter,
        
            [Parameter(Mandatory)]
            [ValidateRange(0,[int32]::MaxValue)]
            [Int32]$InitialSize,
        
            [Parameter(Mandatory)]
            [ValidateRange(0,[int32]::MaxValue)]
            [Int32]$MaximumSize
    )
    Begin 
    {
        # Restvolumen C auslesen
        $VolCSizeRemaining = (Get-Volume -DriveLetter $env:SystemDrive.Replace(":","")).SizeRemaining / 1mb
    }
    Process 
    {
        $Sys = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        
        If($Sys.AutomaticManagedPagefile)
        {
            try 
            {
                $Sys | Set-CimInstance -Property @{AutomaticManagedPageFile = $false} -ErrorAction Stop
                Write-Verbose -Message "Set the AutomaticManagedPageFile to false"
            } catch 
            {
                Write-Warning -Message "Failed to set the AutomaticManagedPageFile property to false in  Win32_ComputerSystem class because $($PSItem.Exception.Message)"
            }
        }
        
        # Configuring the page file size
        try 
        {
            $PageFile = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($DriveLetter):'" -ErrorAction Stop
        } 
        catch 
        {
            Write-Warning -Message "Failed to query Win32_PageFileSetting class because $($PSItem.Exception.Message)"
        }
        
        If($PageFile)
        {
            try 
            {
                $PageFile | Remove-CimInstance -ErrorAction Stop
            } 
            catch 
            {
                Write-Warning -Message "Failed to delete pagefile the Win32_PageFileSetting class because $($PSItem.Exception.Message)"
            }
        }

        # Überprüfen ob noch genug Platz da ist
        if ($MaximumSize -gt $VolCSizeRemaining) 
        {
            Write-Host "Not enough available storage on $DriveLetter"
            exit;
        }

        try 
        {
            New-CimInstance -ClassName Win32_PageFileSetting -Property  @{Name= "$($DriveLetter):\pagefile.sys"} -ErrorAction Stop | Out-Null        

            # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394245%28v=vs.85%29.aspx
            Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($DriveLetter):'" -ErrorAction Stop | Set-CimInstance -Property @{
                InitialSize = $InitialSize ;
                MaximumSize = $MaximumSize ; 
            } -ErrorAction Stop
        
            Write-Verbose -Message "Successfully configured the pagefile on drive letter $DriveLetter"
        
        } 
        catch 
        {
            Write-Warning "Pagefile configuration changed on computer '$Env:COMPUTERNAME'. The computer must be restarted for the changes to take effect."
        }
    }

    End {}    
}