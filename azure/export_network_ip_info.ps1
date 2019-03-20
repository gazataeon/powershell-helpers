####################################################################################
## AzureRM Script to run through all the used IPs in a region then output info on them
####################################################################################

### Variables 
$azureRegion = "westeurope"
$exportLocation = "c:\temp\azureExports"
$logfileName = "$($azureRegion)_networkinfo.txt"
### Body

# Create logdir
if ((Test-Path -Path $exportLocation) -eq $false)
{
    New-Item -Path $exportLocation -ItemType Directory
}

# Archive any old logs
if ((Test-Path -Path "$($exportLocation)\$($logfileName)") -eq $true)
{
    compress-archive -path "$($exportLocation)\$($logfileName)" -destinationpath "$($exportLocation)\$($logfileName)_$((get-date).ToString("yyyyMMdd")).zip" -compressionlevel optimal
    Remove-Item "$($exportLocation)\$($logfileName)" -Force
}



# Get all the vNets
$vnets = Get-AzureRmVirtualNetwork | Where-Object location -eq $azureRegion

# Go through each Vnet and checks the subnets and network devices
foreach ($vnet in $vnets) 
{
   $currentVnet = $vnet.name
   # Get subnets in this vnet
   $subnets = $vnet | Get-AzureRmVirtualNetworkSubnetConfig
   foreach ($subnet in $subnets)
   {
        # Get anything with an IP config
        $ipconfigs = $subnet.IpConfigurations
        foreach ($ipconfig in $ipconfigs)
        {
            # Break down device type
            if ((($ipconfig.id).split('/')).item(7) -eq "networkInterfaces" ) #is a VM
            {
                # Get Object IP
                $objectname = ($ipconfig.id).split('/').item(8)

                # Catch while loop in case of timeout to get IP from object
                $worked = $false
                    while (-not $worked) {
                      try {
                        # Perform command 
                        $nicAddress = (Get-AzureRmNetworkInterface -ErrorAction Stop -ResourceGroupName (($ipconfig.id).split('/').item(4)) -Name ($ipconfig.id).split('/').item(8)).IpConfigurations.PrivateIpAddress

                        $worked = $true  # Will be skipped if the above fails
                      } catch {
                        # error message
                        write-host "error in check, will retry: $($_)"
                      }
                    }
                write-output "$($objectname),NIC,$($nicAddress)" | Tee-Object -FilePath "$($exportLocation)\$($logfileName)-$($currentVnet)" -Append
            }
            elseif((($ipconfig.id).split('/').item(7)) -eq "loadBalancers") #is a LB iP
            {
                $lbName = ($ipconfig.id).split('/').item(8)
                $lbInterfaceName = ($ipconfig.id).split('/').item(10)

                #Catch while loop in case of timeout to get IP from object
                $worked = $false
                    while (-not $worked) {
                      try {
                        #Perform command 
                        $lbInterfaceIP = (((Get-AzureRmLoadBalancer -ErrorAction Stop -ResourceGroupName (($ipconfig.id).split('/').item(4)) -Name ($ipconfig.id).split('/').item(8)).FrontendIpConfigurations) | Where-Object name -eq ($ipconfig.id).split('/').item(10) ).privateipaddress

                        $worked = $true  # Aill be skipped if the above fails
                      } catch {
                        # error message
                        write-host "error in check, will retry: $($_)"
                      }
                    }

                write-output "$($lbName),$($lbInterfaceName),$($lbInterfaceIP)" | Tee-Object -FilePath "$($exportLocation)\$($logfileName)-$($currentVnet)" -Append
            }
            elseif((($ipconfig.id).split('/').item(7)) -eq "virtualNetworkGateways") #is a Virtual Network Gateway IP
            {
                $vGatewayName = ($ipconfig.id).split('/').item(8)
                write-output "$($vGatewayName),VirtualGateway,GatewaySubnet" | Tee-Object -FilePath "$($exportLocation)\$($logfileName)-$($currentVnet)" -Append
            }
            else # something else!
            {
            Write-Host "UNKNOWN DEVICE TYPE" $ipconfig.id
            }
        }

   }

}
