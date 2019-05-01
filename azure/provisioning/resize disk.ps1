#Set your resource group name and VM name as follows:
$rgName = 'vms-rg'
$vmName = 'web-vm1'

#Obtain a reference to your VM as follows:
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName

#Stop the VM before resizing the disk as follows:
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName

#Set the size of the OS disk to the desired value and update the VM as follows:
$vm.StorageProfile.OSDisk.DiskSizeGB = 386
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm