

    
    # setup the VM and resource names
    $vmName = "newVmName"
    $nicName = "$($vmName)-nic"
    $rg = "vms-rg"
    $networkRG = $rg
    $VNetName = "vms-vnet"
    $SubnetName = "web-snet"
    $VMSize = 'Standard_DS11_V2'

    # get the VNET
    $vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $networkRG

    # subnet
    $subnet = get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName


    # Specify the VM name and size
    Write-Output 'Creating VM Config'
    $vm = New-AzureRmVMConfig -VMName $vmName -VMSize $VMSize

    #set VM info from template
    $vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

    # Specify local administrator accoun
    $vm = Set-AzurermVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $VMCredentials -ProvisionVMAgent -EnableAutoUpdate

    # add the nic
    Write-Output "Adding NIC to Config"
    $vm = Add-AzurermVMNetworkInterface -VM $vm -Id $nic.Id
   

    # add OS disk
   $vm = Set-AzureRmVMOSDisk -VM $vm -Name "$($vmName)_sdisk" -VhdUri "https://generalkenobi.blob.core.windows.net/vhds/$($vmName)_osdisk.vhd" -CreateOption Attach

    # add data disk
    write-Output "Adding Data disk"
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name "$($vmName)-DataDisk" -StorageAccountType PremiumLRS -DiskSizeInGB 512 -CreateOption FromImage -Caching ReadWrite -lun 0


    New-AzureRmVM -ResourceGroupName $envRG -Location $Location -VM $vm


    #####################################
    #     LOGIN AS ACCOUNT LOGIN
    #####################################

    $azureConn = Get-AutomationConnection -Name AzureRunAsConnection 
    Add-AzureRMAccount -ServicePrincipal -Tenant $azureConn.TenantID -ApplicationId $azureConn.ApplicationID -CertificateThumbprint $azureConn.CertificateThumbprint

    #####################################
    #         GLOBAL VARIABLES
    #####################################

    $WinRMPassword = (Get-AutomationVariable -Name 'winrmPass')
    $AutomationAccount = "deployment"
    $environment = "uat"
    $envRG = '-uat-rg'
    $automationRG = "automation-rg"
    $networkRG = "uat-vnets"
    $vmType = "web"
    $VMBaseName = "$($environment)-$($vmType)"
    $VNetName = '-vnet'
    $SubnetName = "$($environment)-web-subnet"
    
    $JobId = $PSPrivateMetadata.JobId
    $SlackChannel = $DataRequest.slackchan

    $Location = 'westeurope'
    $Default_VM_Admin = (Get-AutomationPSCredential -Name 'default_vm_admin')
    $AdminUsername = $default_vm_admin.username
    $AdminPassword = $default_vm_admin.password
    $VaultName = (Get-AutomationVariable -Name 'keyVaultName')
    $CertPassword = (Get-AutomationVariable -Name 'keyVaultPass')

   

    $TagsProject = "ProjectWeb"
    $TagsCostCode = "PO-9000"

    $imageName = "W2016-temp-vm"
    $imageRG = "we-core-templates-rg"
    $image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $imageRG
    $managedDataDiskName = "W2016-temp-vm-data1"
    $managedOSDiskName = "W2016-temp-vm_OsDisk_1"

    # UNC password for azure SQL share
    $HostName = $env:COMPUTERNAME

    #####################################
    #          MAIN SCRIPT
    #####################################

   