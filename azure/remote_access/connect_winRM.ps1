
# Display WS-Management Client Trusted Hosts on the
#  current Windows Server 2012 R2 Management Server
Get-Item `
    -Path "WSMan:\localhost\Client\TrustedHosts" ;
 

# Get the Azure Virtual Network Public IP Address IP
Get-AzureRmPublicIpAddress `
    -Name "webvm-pip" `
    -ResourceGroupName "vms-rg" | `
        Select-Object IpAddress ;
$publicIP = Read-Host -Prompt "public ip here"

# Set  IP Address in Azure to be Trusted Hosts on the current Windows Server
Set-Item `
    -Path "WSMan:\localhost\Client\TrustedHosts" `
    -Value "*" `
    -Force ;
 

# check IP is in trusted hosts
Get-Item -Path "WSMan:\localhost\Client\TrustedHosts" ;
 

# Establish a PowerShell Session to the Nano Server
#  in Azure using PowerShell Remoting and input the
#  login credential when it prompt for password.
Enter-PSSession -ComputerName $publicIP -Credential Get-Credential

#OR!

Enter-PSSession `
    -ComputerName $publicIP `
    -Credential ( `
        New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList "administrator", `
            (ConvertTo-SecureString `
                -String "Password!" `
                -AsPlainText `
                -Force)
    )
 

# Display Azure Nano Server Operating System Basic
#  Information using PowerShell Remoting
Get-CimInstance `
    -ClassName Win32_OperatingSystem | `
        Select-Object CSName, Caption, Version, BuildNumber ;