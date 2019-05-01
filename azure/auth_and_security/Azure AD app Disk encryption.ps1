#Prod
$KVRGname = 'core-automation-rg';
$vmName = 'app-vm2';

$KeyVaultName = 'MPPKeyVault';
$VMRGName = 'eu-w-esuite-prod-rg';

$KeyVault = Get-AzrmKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname;
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;

Set-AzVMDiskEncryptionExtension -ResourceGroupName $VMRGname -VMName $vmName -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId;


write-output "start time $(get-date)" 
az vm encryption enable --resource-group "eu-w-esuite-prod-rg" --name "app-vm2" --disk-encryption-keyvault "/subscriptions/ede8fd23-6f01-4ce4-a582-82de76a8271a/resourceGroups/core-automation-rg/providers/Microsoft.KeyVault/vaults/MPPKeyVault"`
--key-encryption-key "https://mppkeyvault.vault.azure.net/keys/diskEncryptEuProd/08504e7212c24f5b83bdddd98a9d2f82" `
--key-encryption-keyvault "/subscriptions/ede8fd23-6f01-4ce4-a582-82de76a8271a/resourceGroups/core-automation-rg/providers/Microsoft.KeyVault/vaults/MPPKeyVault" --volume-type All
write-output "end time $(get-date)"


write-output "start time $(get-date)"
az vm encryption disable --resource-group "eu-w-esuite-prod-rg" --name "app-vm2" --volume-type All
write-output "end time $(get-date)"


#setup AD APP and SP with CLi
az account set --subscription "MPP Global - Azure Master Account"
az ad sp create-for-rbac --name "euwprodvaultsp" --password "HoLiYT2AuX" --skip-assignment
#{
#  "appId": "03bcd8fc-5ca5-4fbd-8354-ecd77f6610ef",
#  "displayName": "euwprodvaultsp",
#  "name": "http://euwprodvaultsp",
#  "password": "HoLiYT2AuX",
#  "tenant": "2344970c-ffe4-46ac-a487-dd21b70efad8"
#}

#enable encryption using azure AD app

az vm encryption enable --resource-group "eu-w-esuite-prod-rg" --name "app-vm2" --aad-client-id "03bcd8fc-5ca5-4fbd-8354-ecd77f6610ef"  `
--aad-client-secret "HoLiYT2AuX" --disk-encryption-keyvault "/subscriptions/ede8fd23-6f01-4ce4-a582-82de76a8271a/resourceGroups/core-automation-rg/providers/Microsoft.KeyVault/vaults/MPPKeyVault" --volume-type "All"
#verify
az vm encryption show --name "app-vm2" --resource-group "eu-w-esuite-prod-rg"