# Shows all images you have access to in Azure - Should now work for PowerShell 6+
import-azurerm 
$images = Get-AzureRMResource -ResourceType Microsoft.Compute/images 
$images.name