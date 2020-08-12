function Get-DSCWebReport
{
    <# https://docs.Microsoft.com/en-us/powershell/dsc/reportserver #>

    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Computername,

        [Parameter(Mandatory = $true)]
        [string]$WebReportURL
    )

    $AgentId = (Get-DscLocalConfigurationManager -CimSession $Computername ).AgentId

    $RequestUri = "$WebReportURL/Nodes(AgentId= '$AgentId')/Reports"
    
    $Request = Invoke-WebRequest -Uri $RequestUri  -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" `
               -UseBasicParsing -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} `
               -ErrorAction SilentlyContinue -ErrorVariable ev

    $Object = ConvertFrom-Json $Request.content

    return $Object.value | Sort-Object {$PSItem."StartTime" -as [datetime] } -Descending | Format-Table -AutoSize
}