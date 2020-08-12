$snapins = Get-ChildItem HKLM:\SOFTWARE\Microsoft\MMC\SnapIns

foreach ($snap in $snapins) {
 
  $snapname=($snap.name.split("\"))[($snap.name.split("\").count-1)]
  New-ItemProperty HKLM:\SOFTWARE\Microsoft\MMC\SnapIns\$snapname SuppressActionsPane -value 1 -propertyType dword

}


