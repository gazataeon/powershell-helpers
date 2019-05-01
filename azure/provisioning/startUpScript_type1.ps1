<#
    .DESCRIPTION
        Gaz's VM start script
#>



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





#All VMs in the below RG will be shut down. No Exceptions!
$VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
		

Foreach ($VM in $VMs) {



#Fetch azure vm tags   
$vmTagsOriginal = (Get-AzureRmResource -ResourceGroupName $ResourceGroupName -Name $VM.Name).Tags

#check to see if vm should start
    foreach ($tag in $vmTagsOriginal){
    
        if ($tag.startup_again -eq "true" )
        {
        #change value
        $vmTagsOriginal.startup_again = "na"
        
        #update azure vm with new tag list
        Set-AzureRmResource -ResourceGroupName $resourceGroupName -ResourceName $vm.Name -ResourceType “Microsoft.Compute/VirtualMachines” -Tag $vmTagsOriginal -force
        
        #start VM
        Start-AzurermVM -ResourceGroupName $ResourceGroupName -Name $VM.Name -ErrorAction SilentlyContinue
        }
        else
        {
        Write-Host "skipping power on of" '"' $vm.Name'"' "due to tag defined"
        }
    }
        
}



#End of file