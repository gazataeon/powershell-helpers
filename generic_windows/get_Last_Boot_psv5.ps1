$machine = "localhost"
$report = @() 
$object = @() 
foreach($machine in $machines) 
{ 
$machine 
$object = Get-WmiObject win32_operatingsystem -ComputerName $machine | Select-Object csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}} 
$report += $object 
} 
$report