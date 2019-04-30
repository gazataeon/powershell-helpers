function get-vm-boottime ($hostname,$resGrp)
{
$vmDetails = Get-AzureRmVM -Name $hostname -ResourceGroupName $resGrp 
$vmLogs = @(Get-AzureRmLog -ResourceGroup $resGrp -DetailedOutput | Where-Object ResourceId -eq $vmDetails.Id | Select-Object OperationName, EventTimestamp | Sort-Object EventTimestamp -Descending)
$vmLogs.item(0).EventTimestamp
}

$bootTime = get-vm-boottime -resGrp "vms-rg" -hostname "web-vm5"

$timeSinceBoot = New-TimeSpan -Start $bootTime -End $(Get-Date).ToUniversalTime()
write-host $timeSinceBoot