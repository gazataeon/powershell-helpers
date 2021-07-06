function enable-NsgFlowLogs($envId, $type)
{
    $resourceGroup =  ((az group list | convertfrom-json) | Where-Object {($_.name -like "$($envId)-$($type)-*") -and ($_.name -notlike "*-asr*")} | Select-Object -first 1).name
    Write-Output "resource group:"
    $resourceGroup
    
    $nsgs = (az network nsg list --resource-group $resourceGroup | convertfrom-json).name
    Write-Output "nsgs:"
    $nsgs
    
    $saName =  (az storage account list --resource-group $resourceGroup | convertfrom-json)
    $saName = ($saname | Where-Object name -eq "$($envId)mpp$($type)sa").name
    Write-Output "SA Name:"
    $saName
    Read-Host -Prompt "carry on?"
    foreach ($nsg in $nsgs)
    {
        az network watcher flow-log configure -g $resourceGroup --enabled true --nsg $nsg --storage-account $saName
    }
    


}