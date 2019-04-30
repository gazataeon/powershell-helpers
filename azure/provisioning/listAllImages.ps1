$temp = Get-AzureRMVMImage -location "West Europe" `
                   -publisherName "MicrosoftWindowsServer" `
                   -sku "2016-Datacenter" `
                   -Offer windowsserver `
      $temp.Item(3).id


# Get a list of Azure Publisher Name that relates
#  to Microsoft Windows Server
Get-AzureRmVMImagePublisher `
    -Location "West Europe" | `
        Where-Object { $_.PublisherName -like "MicrosoftWindowsServer*" } ;
 

 # Get a list of Microsoft Windows Server offering
Get-AzureRmVMImageOffer `
    -Location "West Europe" `
    -PublisherName "MicrosoftWindowsServer" ;


    # Get a list of Microsoft Windows Server Technical Preview SKUs
Get-AzureRmVMImageSku `
    -Location "West Europe" `
    -PublisherName "MicrosoftWindowsServer" `
    -Offer "WindowsServer" | `
        Where { $_.Skus -like "*Technical-Preview*" } ;
 

 # Get a list of Microsoft Windows Server SKUs for Nano Server
 Get-AzureRmVMImageSku `
    -Location "Australia SouthEast" `
    -PublisherName "MicrosoftWindowsServer" `
    -Offer "WindowsServer" | `
        Where { $_.Skus -like "*Nano-Server" } ;