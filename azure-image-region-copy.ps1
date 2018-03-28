
$uniqueDomainName = "<POPULATE THIS>"
$location = "<POPULATE THIS>"


#base image details
$imageName = "<POPULATE THIS>"
$sourceImageRG = "<POPULATE THIS>"
$image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $sourceImageRg 
$templateVmName = "<POPULATE THIS>"
$sourceLocation = "<POPULATE THIS>"
$targetlocation = "<POPULATE THIS>"
$imageContainerName = "templates"
$sourceSubscriptionId =  "<POPULATE THIS>"



function invoke-genLocCode($location)
{
    switch ($location) {
        eastasia { $locCode = "e-asia" }
        southeastasia { $locCode = "se-asia" }
        centralus { $locCode = "c-us" }
        eastus { $locCode = "e-us1" }
        eastus2 { $locCode = "e-us2" }
        westus { $locCode = "w-us1" }
        northcentralus { $locCode = "nc-us" }
        southcentralus { $locCode = "sc-us" }
        northeurope { $locCode = "n-eu" }
        westeurope { $locCode = "w-eu" }
        japanwest { $locCode = "w-jpn" }
        japaneast { $locCode = "e-jpn" }
        brazilsouth { $locCode = "s-bra" }
        australiaeast { $locCode = "e-aus" }
        australiasoutheast { $locCode = "se-aus" }
        southindia { $locCode = "s-ind" }
        centralindia { $locCode = "c-ind" }
        westindia { $locCode = "w-ind" }
        canadacentral { $locCode = "c-can" }
        canadaeast { $locCode = "e-can" }
        uksouth { $locCode = "s-uk" }
        ukwest { $locCode = "w-uk" }
        westcentralus { $locCode = "wc-us" }
        westus2 { $locCode = "w-us2" }
        koreacentral { $locCode = "c-kor" }
        koreasouth { $locCode = "s-kor" }
        francecentral { $locCode = "c-fra" }
        Default { $locCode = "invalid"}
    }

    return $locCode

}

$locCode = invoke-genLocCode -location $targetlocation
$targetRGName = "$($locCode)-templates-rg"
$targetSAName = "mpp$($targetlocation)templatessa"


function invoke-copy-image($targetRGName, $targetSAName, $targetlocation)
{
#Check for the storage account and resource group
write-output "make sure RG+SA in target location exists"
$targetRG = Get-AzureRmResourceGroup -Location $targetlocation| Where-Object resourcegroupname -eq $targetRGName
If ($targetRG -eq $null)
    {
    write-output "no resourcegroup found, creating..."
    New-AzureRmResourceGroup -Location $targetlocation -Name $targetImageRg 
    }

$targetStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $targetRGName | Where-Object StorageAccountName -EQ $targetSAName
if ($targetStorageAccount -eq $null)
    {
    write-output "No storage account found, will create one"
    $targetStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $targetRGName -Name $targetSAName -Location $targetlocation -SkuName Standard_LRS
    }


#snapshot OS and data disk1
write-output "Create a snapshot of the OS and data disks from the generalized VM"
$vm = Get-AzureRmVM -ResourceGroupName $sourceImageRG -Name $templateVmName
$osDisk = Get-AzureRmDisk -ResourceGroupName $sourceImageRg -DiskName $vm.StorageProfile.OsDisk.Name
$dataDisk = Get-AzureRmDisk -ResourceGroupName $sourceImageRg -DiskName $vm.StorageProfile.DataDisks.Item(0).name

#Create snapshot config from disk IDs
$OSsnapshot = New-AzureRmSnapshotConfig -SourceUri $osDisk.Id -CreateOption Copy -Location $sourceLocation 
$dataSnapshot = New-AzureRmSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location $sourceLocation 
 
write-output "Create the name of the snapshot, using the current region in the name."
$snapshotName = $imageName + "-" + $sourceLocation + "-snap"
$dataSnapshotName = $imageName + "-" + $sourceLocation + "-data-snap"

#OS
write-output "Get/create the source OS snapshot"
$OSsnap = Get-AzureRmSnapshot -ResourceGroupName $sourceImageRg |Where-Object SnapshotName -eq $snapshotName
if ($OSsnap -eq $null)
{
$OSsnap = New-AzureRmSnapshot -ResourceGroupName $sourceImageRg -Snapshot $OSsnapshot -SnapshotName $snapshotName  
}

#data
write-output "Get/create the source data snapshot"
$dataSnap = Get-AzureRmSnapshot -ResourceGroupName $sourceImageRg |Where-Object SnapshotName -eq $dataSnapshotName
if ($dataSnap -eq $null)
{
write-output "Creating new data snapshot"
$dataSnap = New-AzureRmSnapshot -ResourceGroupName $sourceImageRg -Snapshot $dataSnapshot -SnapshotName $dataSnapshotName  
}

#Get the snapshot access signatures
write-output "Create a Shared Access Signature for the source snapshots"
$snapSasUrl = Grant-AzureRmSnapshotAccess -ResourceGroupName $sourceImageRg -SnapshotName $snapshotName -DurationInSecond 3600 -Access Read
$dataSnapSasUrl = Grant-AzureRmSnapshotAccess -ResourceGroupName $sourceImageRg -SnapshotName $dataSnapshotName -DurationInSecond 3600 -Access Read


#Make sure we have a storage account to copy to! 
write-output "Setting up the target storage account in the other region"
$targetStorageContext = (Get-AzureRmStorageAccount -ResourceGroupName $targetRGName -Name $targetSAName).Context
if ((get-AzureStorageContainer -Context $targetStorageContext | Where-Object name -eq templates) -eq $null)
{
New-AzureStorageContainer -Name $imageContainerName -Context $targetStorageContext -Permission Container
}
else
{
Write-Output "Target Storage account container already exists"
}

#New disk names 
$imageBlobName = $osDisk.Name
$dataBlobName = $dataDisk.Name

write-output "Use the SAS URL to copy the blob to the target storage account "
#OS Disk Copy
write-output "Copying OS Blob"
Start-AzureStorageBlobCopy -AbsoluteUri $snapSasUrl.AccessSAS -DestContainer $imageContainerName -DestContext $targetStorageContext -DestBlob $imageBlobName
Get-AzureStorageBlobCopyState -Container $imageContainerName -Blob $imageBlobName -Context $targetStorageContext -WaitForComplete

Write-Output "copying Data blob"
Start-AzureStorageBlobCopy -AbsoluteUri $dataSnapSasUrl.AccessSAS -DestContainer $imageContainerName -DestContext $targetStorageContext -DestBlob $dataBlobName
Get-AzureStorageBlobCopyState -Container $imageContainerName -Blob $dataBlobName -Context $targetStorageContext -WaitForComplete

#get the URLs for the target Blob files 
write-output "Get the full URI to the blobs"
$osDiskVhdUri = ($targetStorageContext.BlobEndPoint + $imageContainerName + "/" + $imageBlobName)
$dataDiskVhdUri = ($targetStorageContext.BlobEndPoint + $imageContainerName + "/" + $dataBlobName)
 

write-output "Build up the snapshot configuration, using the target storage account's resource ID"
$OSsnapshotConfig = New-AzureRmSnapshotConfig -AccountType StandardLRS `
                                            -OsType Windows `
                                            -Location $targetlocation `
                                            -CreateOption Import `
                                            -SourceUri $osDiskVhdUri `
                                            -StorageAccountId "/subscriptions/${sourceSubscriptionId}/resourceGroups/${targetRGName}/providers/Microsoft.Storage/storageAccounts/${targetSAName}"

$dataSnapshotConfig = New-AzureRmSnapshotConfig -AccountType StandardLRS `
                                            -OsType Windows `
                                            -Location $targetlocation `
                                            -CreateOption Import `
                                            -SourceUri $dataDiskVhdUri `
                                            -StorageAccountId "/subscriptions/${sourceSubscriptionId}/resourceGroups/${targetRGName}/providers/Microsoft.Storage/storageAccounts/${targetSAName}"



$snapshotName = $imageName + "-" + $targetlocation + "-snap"
$dataSnapshotName = $imageName + "-" + $targetlocation + "-data-snap"

#OS Disk Snapshot
write-output "Creating the new OS snapshot in the target region"
New-AzureRmSnapshot -ResourceGroupName $targetRGName -SnapshotName $snapshotName -Snapshot $OSsnapshotConfig
#Data Disk Snapshot
New-AzureRmSnapshot -ResourceGroupName $targetRGName -SnapshotName $dataSnapshotName -Snapshot $dataSnapshotConfig 

# create a new Image from the copied snapshot
write-output "create a new Image from the copied snapshot"

$targetsnap = Get-AzureRmSnapshot -ResourceGroupName $targetRGName -SnapshotName $snapshotName 
$dataSnap =  Get-AzureRmSnapshot -ResourceGroupName $targetRGName -SnapshotName $dataSnapshotName 
 
$imageConfig = New-AzureRmImageConfig -Location $targetlocation
 
#Add OS Disk
Set-AzureRmImageOsDisk -Image $imageConfig `
                        -OsType Windows `
                        -OsState Generalized `
                        -SnapshotId $targetsnap.Id 

#Add data disk
Add-AzureRmImageDataDisk -Image $imageConfig -SnapshotId $dataSnap.ID


#create image 
New-AzureRmImage -ResourceGroupName $targetRGName `
                 -ImageName $imageName `
                 -Image $imageConfig


}




#check image RG exists
$targetRGcheck = Get-AzureRmResourceGroup | Where-Object ResourceGroupName -EQ $targetRGName

if ($targetRGcheck -eq $null)
{
write-output "No target Resource group, will create"
New-AzureRmResourceGroup -Name $targetRGName -Location $targetlocation 
}

#check image exists in location
$targetImage = Get-AzureRmImage -ResourceGroupName $targetRGName | Where-Object Name -eq $imageName
if ($targetImage -eq $null)
{
    invoke-copy-image -targetRGName $targetRGName -targetSAName $targetSAName -targetlocation $targetlocation
}
else
{
    Write-Output "Image already exists in target Region"
}
$image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $targetRGName 
