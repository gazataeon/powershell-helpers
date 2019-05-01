<#
    .DESCRIPTION
        Gaz's shutdown script

        Note there's some mad stuff im doing with tags to keep track of the machines inten ded states should admins want them excluded from shutdowns/startups
#>
$ResourceGroupName = "workstations" Get-AutomationVariable -Name 'autoshutdown_rg'

#Login Bit
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}


########Shutdown Logic

#All VMs in the below RG will be shut down. No Exceptions! Except for the Exceptions!
$VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName 

Foreach ($VM in $VMs) {

$vmdetails = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Status
foreach ($vmdetail in $vmdetails.Statuses) {
    if($vmdetail.Code -notlike "PowerState/deallocated"){

    #Fetch azure vm tags   
    $vmTagsOriginal = (Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Compute/virtualMachines" -Name $VM.Name).Tags

    #check to see if vm should start

        if ($vmTagsOriginal.stayon -eq "true" )
        {
        write-host "Server shutdown skipped for " $vm.name
        }
        else
        {
        #shut down VM
        Stop-AzurermVM -ResourceGroupName $ResourceGroupName -Name $VM.Name -force -ErrorAction SilentlyContinue
        
        #check to see if tag exists
        if ($vmTagsOriginal.startup_again)
            {
            $vmTagsOriginal.startup_again = "true"
            Set-AzureRmResource -ResourceGroupName $resourceGroupName -ResourceName $vm.Name -ResourceType “Microsoft.Compute/VirtualMachines” -Tag $vmTagsOriginal -force
            }
            else
            {
            $vmTagsOriginal += @{startup_again="true"} 
            Set-AzureRmResource -ResourceGroupName $ResourceGroupName -Name $VM.Name -Tag $vmTagsOriginal -ResourceType "Microsoft.Compute/virtualMachines" -Force 
            } 
               
        }
    }
    else
    {
    Write-Output ""
    Write-Output "Skipping "$VM.Name "as it is already " $vmdetail.Code
    Write-Output ""
    }
   }     
}

