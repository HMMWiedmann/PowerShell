# SQL VSS Writer
$SQLVSSWriter = Get-Service -Name "SQLWriter"
if ($sqlVSSWriter.Status -ne "Running") 
{
    Start-Service -Name "SQLWriter"
}
else 
{
    Restart-Service -Name "SQLWriter" -Force
}

# VSS Dienst
Restart-Service -Name "VSS" -Force

# COM+ Dienste
Restart-Service -Name "EventSystem","COMSysApp" -Force