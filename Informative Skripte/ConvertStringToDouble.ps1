$raw = $SNMP.Get(".1.3.6.1.4.1.24681.1.2.17.1.5.1")
$str = $raw.Split(" ")[0]
$int = [double]$str