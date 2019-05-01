#####################################
#                                   #
# Create a VM with two public IPs  ##
# Interactive script!!              #
#####################################



#####################################
#             VARIABLES             #
#####################################

$vmname = "eu-w-sftp-vm1"
$resourceGroup = "eu-w-sftp-rg"
$adminUsername = 'adminguy'
$adminPassword = 'aPassword!'
$vmSize = 'Standard_DS1_v2'  #default only
$azureLocation = "westeurope"
$SubnetID = "eu-w-sftp-snet"


#####################################
#          SCRIPT BODY              #
#####################################

Write-host "This Script is going to create a windows 2012 box, change it if you dont like that!" -ForegroundColor Red
# VM size check

Write-host ""
Write-host "Do you need a list of VM sizes?"
$readhost = Read-host " (y / n)"
switch ($Readhost)
{
Y {Get-AzureRmVmSize -Location $AzureLocation | Sort-Object Name | Format-Table Name, NumberOfCores, MemoryInMB, MaxDataDiskCount -AutoSize}
N {write-host "Okay, enter the size you need"}
}

$vmSize = read-host -Prompt 'enter the VM size, eg Standard_DS1_v2'

#Add VM size
$vm = New-AzurermVMConfig -VMName $vmName -VMSize $vmSize 

#Get Network info
#List and select Virtual Networks 
$VMNetsdump = @(Get-AzureRmVirtualNetwork)
Write-host "Select a Virtual Network number" -ForegroundColor Yellow 
for ($i=0;$i -lt $VMNetsdump.Count; $i++) {write-host $i $VMNetsdump.Item($i).name}
$readhost = read-host -prompt 'Press number'
write-host ""
$vnetselected=$VMNetsdump.Item($readhost).name;write-host "Selected:" $VMNetsdump.Item($readhost).name

#List and select Subnets
$subnets = @(Get-AzureRmVirtualNetwork | Where-Object {$_.name -eq $vnetselected} | get-AzureRmVirtualNetworkSubnetConfig)
Write-host "Select a Subnet number" -ForegroundColor Yellow 
for ($i=0;$i -lt $subnets.Count; $i++) {write-host $i $subnets.Item($i).name}
$readhost = read-host -prompt 'Press number'
write-host ""
$subnetselected = $subnets.Item($readhost).name;write-host "Selected:" $subnets.Item($readhost).name

#Get the Subnet ID to which to connect the New NIC
$subnetid = $subnets.Item($readhost).id

# Create a public IP address and specify a DNS name
$pip1 = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $azureLocation `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name ($vmName+"-pip1")

$pip2 = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $azureLocation `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name ($vmName+"-pip2")

#create the NICs
$nic1 = New-AzureRmNetworkInterface -Name ($vmName+"-nic1") -ResourceGroupName $resourceGroup -Location $azureLocation -SubnetId $SubnetID -PublicIpAddressId $pip1.Id
$nic2 = New-AzureRmNetworkInterface -Name ($vmName+"-nic2") -ResourceGroupName $resourceGroup -Location $azureLocation -SubnetId $SubnetID -PublicIpAddressId $pip2.Id

#Get the NICs
$NewNIC1 =  Get-AzureRmNetworkInterface -Name $nic1.name -ResourceGroupName $resourceGroup
$NewNIC2 =  Get-AzureRmNetworkInterface -Name $nic2.name -ResourceGroupName $resourceGroup

#Add the NIC to the VM
$VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NewNIC1.Id
$VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NewNIC2.Id

#make nic1 primary
$vm.NetworkProfile.NetworkInterfaces.Item(0).primary = $true

#set the local admin account
$SecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($adminUsername, $SecurePassword); 

#add local login
$vm = Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmname -Credential $Credentials -VM $vm

#set vm image
$vm = Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version latest -vm $vm

#create VM
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $azureLocation -VM $vm