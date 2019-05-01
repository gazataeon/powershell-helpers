# Create a new Azure Resource Manager Virtual Network
New-AzureRmVirtualNetwork `
    -ResourceGroupName "ARM-DEV-ENV" `
    -Location "Australia Southeast" `
    -Name "ARM-VN-DEV-ENV" `
    -AddressPrefix "192.168.1.0/24" `
    -Subnet (New-AzureRmVirtualNetworkSubnetConfig `
                -Name "GatewaySubnet" `
                -AddressPrefix "192.168.1.248/29"),
            (New-AzureRmVirtualNetworkSubnetConfig `
                -Name "Subnet-DEV-ENV" `
                -AddressPrefix "192.168.1.0/25") `
    -Tag @{Name="Department";Value="IT"}, `
         @{Name="CostCentre";Value="Innovation"}, `
         @{Name="Function";Value="Development"} ;