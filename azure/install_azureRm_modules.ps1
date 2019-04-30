    # Install the Azure Resource Manager modules
#  from the PowerShell Gallery
Install-Module `
    -Name AzureRM `
    -Confirm:$False `
    -Force ;


    # Verify AzureRM PowerShell Module is installed
#  by displaying first 10 AzureRM Cmdlets
Get-Command | `
    Where { $_.ModuleName -match "AzureRM" } | `
        Select `
            -First 10 ;