$eventlog = Get-WinEvent -LogName Security | ?{$_.Id -like "4625"} | select -First 1

$EmailFrom = "admin3@nts-powerserver.de"
$EmailTo = "admin3@nts-powerserver.de"
$Subject = "Intrusion detected!"
$Body = "Fehlerhafter Login-Versuch!" + [System.Environment]::NewLine + [System.Environment]::NewLine
$Body += "TimeCreated: " + $eventlog.TimeCreated.ToString() + ([System.Environment]::NewLine)
$Body += "MachineName: " + $eventlog.MachineName + ([System.Environment]::NewLine) + ([System.Environment]::NewLine)
$Body += "EventMessage: " + $eventlog.Message + [System.Environment]::NewLine

$SMTPServer = "ve2k10-01.nts-powerserver.de"
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, 25)
$SMTPClient.EnableSsl = $false
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("admin3@nts-powerserver.de", "C0mplex");
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)