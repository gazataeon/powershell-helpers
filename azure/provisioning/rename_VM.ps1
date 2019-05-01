    # Allows you to rename a VM by Recreating it.
    
  
        
    #~~~~~~~~~~~~~~~SET THESE!!!~~~~~~~~~~~~~~~~~~
    #Current Values
    write-host 'Select Subscription'
    write-host '0 Production'
    write-host '1 SDLC'
    write-host '2 Support Services'
    $resultSub = read-host

    switch ($resultSub)
    {
        0 {$selectSub="Production" }
        1 {$selectSub="SDLC"}
        2 {$selectSub="Support Services"} 
    }
    Get-AzureRmSubscription -SubscriptionName $selectSub | Select-AzureRmSubscription
    
    $readCurVmname = read-host -prompt 'Enter Current vm name to be changed'
    $readrg = read-host -prompt 'Enter Resource group name'
    
    #Target Values
    $newVmName = read-host -prompt 'Enter new VM name'


    $newResourceGroup = read-host -prompt 'Enter new Resource Group name'
    

    
    
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
    #to log saved variables
    $outFile = "C:\temp\outfile_"+$readCurVmname+".txt"
    
    #Correct NIC Name convention
    $newNICName = $newVmName+'NIC’
    #This generates the storage account name based on the Azure Conventions we use.
    $destStorageAccountName = $newVmName.substring(0,$newVmName.Length-2) + "str01casfs"

   
    #Get VM Details
    $OriginalVM = get-azurermvm -ResourceGroupName $readrg -Name $readCurVmname

    $oldNic = Get-AzureRmNetworkInterface | Where-Object {$_.VirtualMachine.Id -eq $OriginalVM.Id}
    
    #Location For VM
    $AzureLocation = $OriginalVM.Location
    
    #Get IP address
    $oldIP = $oldNic.IpConfigurations[0].PrivateIpAddress

    #New NIC Resource Group
    $newNICResourceGroup = $newResourceGroup
    #New NIC creation location
    $Location = $oldNic.Location
    #Get IP address
    $oldIP = $oldnic.IpConfigurations[0].PrivateIpAddress
    # Get the Subnet ID to which to connect the New NIC
    $subnetID=$oldNic.IpConfigurations.Item(0).subnet.id
    

    #Output VM details to file - use in the event of a screw up
    "VM Name: " | Out-File -FilePath $outFile 
    $OriginalVM.Name | Out-File -FilePath $outFile -Append

    "Extensions: " | Out-File -FilePath $outFile -Append
    $OriginalVM.Extensions | Out-File -FilePath $outFile -Append

    "VMSize: " | Out-File -FilePath $outFile -Append
    $OriginalVM.HardwareProfile.VmSize | Out-File -FilePath $outFile -Append

    "NIC: " | Out-File -FilePath $outFile -Append
    $OriginalVM.NetworkProfile.NetworkInterfaces[0].Id | Out-File -FilePath $outFile -Append

    "OSType: " | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.OsDisk.OsType | Out-File -FilePath $outFile -Append

    "OS Disk: " | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.OsDisk.Vhd.Uri | Out-File -FilePath $outFile -Append


    if ($OriginalVM.StorageProfile.DataDisks) {
    "Data Disk(s): " | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.DataDisks | Out-File -FilePath $outFile -Append
    }

    #Remove the original VM
    Remove-AzureRmVM -ResourceGroupName $readrg -Name $readCurVmname

    #remove the old NIC
    remove-azurermnetworkinterface -name $oldNic.Name -ResourceGroup $oldNic.ResourceGroupName

    #create the new resource group
    New-AzureRmResourceGroup -location $AzureLocation -name $newResourceGroup
    
    #Create the storage account
    New-AzureRmStorageAccount -ResourceGroupName $newResourceGroup -AccountName $destStorageAccountName -Location $OriginalVM.Location -Type "Standard_LRS"


    #####Move he VHD
    # VHD blob to copy # 
    $blobName = ($OriginalVM.StorageProfile.OsDisk.Vhd.Uri.Split("/")[-1])
    #$blobName = ($OriginalVM.StorageProfile.OsDisk.Name)+".vhd"
    $newBlobName = ($newVmName+"-osDisk")+".vhd"

    # Source Storage Account Information #
    $sourceKey = (Get-AzureRmStorageAccountKey -Name $sourceStorageAccountName -ResourceGroupName $rg).Value[0]
    $sourceContext = new-azurestoragecontext -storageaccountname $sourceStorageAccountName -storageaccountkey $sourceKey
    
    $sourceContainer = "vhds"

    # Destination Storage Account Information #

    $destinationKey = (Get-AzureRmStorageAccountKey -Name $destStorageAccountName -ResourceGroupName $newResourceGroup).Value[0]
    $destinationContext = New-AzureStorageContext –StorageAccountName $destStorageAccountName -StorageAccountKey $destinationKey  

    # Create the destination container #
    $destinationContainerName = "vhds"
    New-AzureStorageContainer -Name $destinationContainerName -Context $destinationContext 

    # Copy the blob # 
    $blobCopy = Start-AzureStorageBlobCopy -DestContainer $destinationContainerName `
                        -DestContext $destinationContext `
                        -DestBlob $newBlobName `
                        -SrcBlob $blobName `
                        -Context $sourceContext `
                        -SrcContainer $sourceContainer

    
    #check status
    while(($blobCopy | Get-AzureStorageBlobCopyState).Status -eq "Pending")
{
    Start-Sleep -s 30
    $copypercent = (($blobCopy | Get-AzureStorageBlobCopyState ).bytescopied / ($blobCopy | Get-AzureStorageBlobCopyState).totalbytes)
    $blobCopy | Get-AzureStorageBlobCopyState 
    Echo "Copied so far:"
    “{0:P}” -f $copypercent

}

    #get rid of old disk (ONY IF ABOVE IS SUCCESSFUL!)
    Remove-AzureStorageBlob -Container $sourceContainer -Context $sourceContext -Blob $blobName

    #NEW OS DISK VHD URI
    $copiedOSDiskVHD = "http://"+$destStorageAccountName+".blob.core.windows.net/"+$destinationContainerName+"/"+$newBlobName


   
        
        
    #Create new availability set if it does not exist
    $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $newResourceGroup -Name $newAvailSetName -ErrorAction Ignore
    if (-Not $availSet) {
    $availset = New-AzureRmAvailabilitySet -ResourceGroupName $newResourceGroup -Name $newAvailSetName -Location $OriginalVM.Location
    }

    ##Write something here to remove the old AS
    #
    #
    #


    #Create the new NIC Interface
    $newnic = New-AzureRmNetworkInterface -Name $newNICName -ResourceGroupName $newNICResourceGroup -Location $Location -SubnetId $SubnetID -PrivateIpAddress $oldIP

    

    #Create the basic configuration for the replacement VM
    $newVM = New-AzureRmVMConfig -VMName $newVmName -VMSize $OriginalVM.HardwareProfile.VmSize -AvailabilitySetId $availSet.Id
    Set-AzureRmVMOSDisk -VM $NewVM -VhdUri $copiedOSDiskVHD  -Name ($newVmName+"-osDisk") -CreateOption Attach -Windows

  
   #Copy and add the Data Disks
    foreach ($disk in $OriginalVM.StorageProfile.DataDisks ) { 
    $srcDataDiskName = ($disk.name)+".vhd"
    $dstDataDiskName = $newVmName+"-disk"+($disk.lun)+".vhd"
    $dataDiskCopy = Start-AzureStorageBlobCopy -DestContainer $destinationContainerName `
                        -DestContext $destinationContext `
                        -DestBlob $dstDataDiskName `
                        -SrcBlob $srcDataDiskName `
                        -Context $sourceContext `
                        -SrcContainer $sourceContainer

    $newDataDiskURI = "http://"+$destStorageAccountName+".blob.core.windows.net/"+$destinationContainerName+"/"+$dstDataDiskName
    Add-AzureRmVMDataDisk -VM $newVM -Name ($newVmName+"-disk"+($disk.lun)) -VhdUri $disk.Vhd.Uri -Caching $disk.Caching -Lun $disk.Lun -CreateOption Attach -DiskSizeInGB $disk.DiskSizeGB
    
       while(($dataDiskCopy | Get-AzureStorageBlobCopyState).Status -eq "Pending")
        {
         $dataDiskCopy | Get-AzureStorageBlobCopyState
         Echo "Copied so far:"
           “{0:P}” -f $copypercent
         Start-Sleep -s 10
        }

    }




    #Add NIC(s)
    foreach ($nic in $OriginalVM.NetworkInterfaceIDs) {
        Add-AzureRmVMNetworkInterface -VM $NewVM -Id $newnic.id
    }

    
    #Create the VM
    $vmcreation = New-AzureRmVM -ResourceGroupName $newResourceGroup -Location $OriginalVM.Location -VM $NewVM -DisableBginfoExtension

    $vmcreation.ProvisioningState

    ###Final manual activities, you need to change the diag storage account, and also remove the old resource group if it is empty/no longer required.
    ##also rename the VM in windows