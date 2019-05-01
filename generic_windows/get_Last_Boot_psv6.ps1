# Simple last boot time function 

$lastBootTime = Get-CimInstance -ClassName win32_operatingsystem | Select-Object csname, LastBootUpTime
return $lastBootTime.LastBootUpTime