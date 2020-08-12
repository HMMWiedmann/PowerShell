$wmifilter = (Get-GPO -Name "TEST").wmifilter
$newgpo = Get-GPO -name "TEST 2"

$newgpo.wmifilter = $wmifilter