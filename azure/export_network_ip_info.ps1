####################################################################################
## AzureRM Script to run through all the used IPs in a region then output info on them
####################################################################################

### Variables 
$azureRegion = "westeurope"
$exportLocation = "c:\temp\azureExports"
$logfileName = "ipinfo_$($azureRegion)_"
$logExt = ".csv"
### Body

# Create logdir
if ((Test-Path -Path $exportLocation) -eq $false)
{
	New-Item -Path $exportLocation -ItemType Directory
	New-Item -Path "$($exportLocation)\archives" -ItemType Directory
}

# Archive any old logs
if ((Test-Path -Path "$($exportLocation)\*.*") -eq $true)
{
	#zip up all files here not already a zip
	Move-Item -Path "*.zip" -Destination "$($exportLocation)\archives"
	Get-ChildItem "$($exportLocation)" | Where-Object name -NotLike "*.zip*" | Compress-Archive -DestinationPath "$($exportLocation)\$($logfileName)_$((get-date).ToString("yyyyMMdd")).zip" -compressionlevel optimal
	Move-Item -Path "*.zip" -Destination "$($exportLocation)\archives"
	#delete any non zipped files
	Remove-Item "$($exportLocation)\*.*"
}



# Get all the vNets
$vnets = Get-AzureRmVirtualNetwork | Where-Object location -EQ $azureRegion

# Go through each Vnet and checks the subnets and network devices
foreach ($vnet in $vnets)
{
	$currentVnet = $vnet.Name
	# Get subnets in this vnet
	$subnets = $vnet | Get-AzureRmVirtualNetworkSubnetConfig
	foreach ($subnet in $subnets)
	{
		$currentSubnet = $subnet.Name
		# Get anything with an IP config
		$ipconfigs = $subnet.IpConfigurations
		foreach ($ipconfig in $ipconfigs)
		{
			# Break down device type
			if ((($ipconfig.id).split('/')).item(7) -eq "networkInterfaces") #Device is a VM
			{
				# Get Object IP (in this case the nic name itself)
				$objectname = ($ipconfig.id).split('/').item(8)

				# Catch while loop in case of timeout to get IP from object
				$worked = $false
				while (-not $worked) {
					try {
						# Perform command 
						#$nicAddress = (Get-AzureRmNetworkInterface -ErrorAction Stop -ResourceGroupName (($ipconfig.id).split('/').item(4)) -Name ($ipconfig.id).split('/').item(8)).IpConfigurations.PrivateIpAddress
						$nic = (Get-AzureRmNetworkInterface -ErrorAction Stop -ResourceGroupName (($ipconfig.id).split('/').item(4)) -Name ($ipconfig.id).split('/').item(8))
						$nicAddress = $nic.IpConfigurations.PrivateIpAddress
						#check to see if Nic is actually attached to a vm
						if ($nic.VirtualMachine -ne $null)
						{
							$nicsVM = ($nic.VirtualMachine.id).split('/') | Select-Object -Last 1
						}
						else
						{
							$nicsVM = "UNATTACHED_NIC-$($objectname)"
						}



						$worked = $true # Will be skipped if the above fails
					} catch {
						# error message
						Write-Host "error in check, will retry: $($_)"
					}
				}
				Write-Output "$($nicsVM),NIC,$($nicAddress),$($currentSubnet)" | Tee-Object -FilePath "$($exportLocation)\$($logfileName)-$($currentVnet)$($logExt)" -Append
			}
			elseif ((($ipconfig.id).split('/').item(7)) -eq "loadBalancers") #is a LB iP
			{
				$lbName = ($ipconfig.id).split('/').item(8)
				$lbInterfaceName = ($ipconfig.id).split('/').item(10)

				#Catch while loop in case of timeout to get IP from object
				$worked = $false
				while (-not $worked) {
					try {
						#Perform command 
						$lbInterfaceIP = (((Get-AzureRmLoadBalancer -ErrorAction Stop -ResourceGroupName (($ipconfig.id).split('/').item(4)) -Name ($ipconfig.id).split('/').item(8)).FrontendIpConfigurations) | Where-Object name -EQ ($ipconfig.id).split('/').item(10)).PrivateIpAddress

						$worked = $true # Aill be skipped if the above fails
					} catch {
						# error message
						Write-Host "error in check, will retry: $($_)"
					}
				}

				Write-Output "$($lbName),$($lbInterfaceName),$($lbInterfaceIP),$($currentSubnet)" | Tee-Object -FilePath "$($exportLocation)\$($logfileName)-$($currentVnet)$($logExt)" -Append
			}
			elseif ((($ipconfig.id).split('/').item(7)) -eq "virtualNetworkGateways") #is a Virtual Network Gateway IP
			{
				$vGatewayName = ($ipconfig.id).split('/').item(8)
				Write-Output "$($vGatewayName),VirtualGateway,GatewaySubnet,$($currentSubnet)" | Tee-Object -FilePath "$($exportLocation)\$($logfileName)-$($currentVnet)$($logExt)" -Append
			}
			else # something else!
			{
				Write-Host "UNKNOWN DEVICE TYPE" $ipconfig.id
			}
		}

	}

}
