Install-Module AzureRM.Compute -RequiredVersion 2.6.0
Login-AzureRmAccount

#Create some variables.
$vmName = "sourceVMName" 
$rgName = "templates-rg" 
$location = "WestEurope" 
$imageName = "Windows2016-Image"

#Make sure the VM has been deallocated.
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force


#Set the status of the virtual machine to Generalized.
Set-AzureRmVm -ResourceGroupName $rgName -Name $vmName -Generalized


#Get the virtual machine.
$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName


#Create the image configuration.
$image = New-AzureRmImageConfig -Location $location -SourceVirtualMachineId $vm.ID 


#Create the image.
New-AzureRmImage -Image $image -ImageName $imageName -ResourceGroupName $rgName