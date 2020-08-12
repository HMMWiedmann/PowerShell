function Get-AvailableDriveLetter 
{
    $UsedLetters = (Get-PSDrive -PSProvider FileSystem).Name

    $AllLetters = "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"

    foreach($driveletter in $AllLetters)
    {
        if ($UsedLetters -notcontains $driveletter) 
        {
            Write-Host $driveletter
        }
    }
}