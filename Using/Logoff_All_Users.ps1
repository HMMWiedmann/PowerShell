if ($null -ne $ExeptUsers) 
{
    $EUsers = $ExeptUsers.split(",")
}

try {
    $serverName = "localhost"
    $sessions = qwinsta /server $serverName | `
        Where-Object { $_ -notmatch '^ SESSIONNAME' } | `
        ForEach-Object {
            $item = "" | Select-Object "Active", "SessionName", "Username", "Id", "State", "Type", "Device"
            $item.Active = $_.Substring(0,1) -match '>'
            $item.SessionName = $_.Substring(1,18).Trim()
            $item.Username = $_.Substring(19,20).Trim()
            $item.Id = $_.Substring(39,9).Trim()
            $item.State = $_.Substring(48,8).Trim()
            $item.Type = $_.Substring(56,12).Trim()
            $item.Device = $_.Substring(68).Trim()
            $item
        } 

    $sessions = $sessions | Where-Object -Property Username -NE "BENUTZERNAME"

    if ($null -ne $EUsers) 
    {
        foreach ($User in $EUsers)
        {
            $sessions = $sessions.Where{ $PSItem.Username -ne $User }
        }
    }    
}
catch {
    Write-Host "Es gab einen Fehler beim Abrufen der angemeldeten Benutzer"
    Write-Host $PSItem.Exception.Message
}

foreach ($session in $sessions)
{
    try {
        if ($session.Username -ne "" -or $session.Username.Length -gt 1)
        {
            Write-Host "Benutzer $($session.Username) wurde abgemeldet"
            logoff /server $serverName $session.Id
        }
    }
    catch {
        Write-Host "Username: $($session.UserName) konnte nicht abgemeldet werden."
    }    
}