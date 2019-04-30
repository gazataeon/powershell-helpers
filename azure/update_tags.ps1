$vmName = "web-vm"
$vmresourceGroupName = "web-rg"

$tags = (Get-AzureRmVM  -ResourceName $vmName -ResourceGroupName $vmresourceGroupName).Tags
$tags += @{CostCode="webServers9000"}
Set-AzureRmResource -ResourceGroupName $vmresourceGroupName -ResourceName $vmName -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $tags -Force