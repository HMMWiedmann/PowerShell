$Servers = (Get-ADComputer -Filter { DNSHostName -like "HYPERV-*" }).DNSHostName

foreach ($Comp in $Servers)
{
    Invoke-Command -ComputerName $Comp -ScriptBlock `
    {
        $Platznummer = $env:COMPUTERNAME.Substring($ENV:COMPUTERNAME.Length - 2)

        # Local Client Credentials
        [string]$LocalAdmin = "Admin"
        $LocalPWD = ConvertTo-SecureString "C0mplex" -AsPlainText -Force
        $VMCred = New-Object -TypeName System.Management.Automation.PSCredential ($LocalAdmin, $LocalPWD)

        Invoke-Command -VMName "$($Platznummer)-VWIN10-04" -Credential $VMCred -ScriptBlock `
        {
            $OutputPath = "\\IC-VFILE01\Autopilot$"
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
            C:\Scripts\Get-WindowsAutoPilotInfo.ps1 -OutputFile "$($OutputPath)\$($env:COMPUTERNAME).csv"
        }
    }
}