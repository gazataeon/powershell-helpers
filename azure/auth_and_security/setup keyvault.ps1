#variables
$certPassword = "MyCertPassword"
$vaultSecret = "MySecretVaultPass"
$resourceGrp 
$vaultName = "MyKeyVault"

$certificateName = $env:COMPUTERNAME
$fileName = $certificateName+".pfx"

#import modules
#Install-Module -Name AzureRM.KeyVault
#Import-Module AzureRM.KeyVault

#register for keyvault 
#Register-AzureRmResourceProvider -ProviderNamespace Microsoft.KeyVault
#get-AzureRmResourceProvider -ProviderNamespace Microsoft.keyvault

#new keyvault
#New-AzureRmKeyVault -VaultName 'MPPKeyVault' -ResourceGroupName 'core-automation-rg' -Location 'West Europe' -EnabledForDeployment


#create a cert
    #$certificateName = "somename"

$thumbprint = (New-SelfSignedCertificate -DnsName $certificateName -CertStoreLocation Cert:\CurrentUser\My -KeySpec KeyExchange).Thumbprint

$cert = (Get-ChildItem -Path cert:\CurrentUser\My\$thumbprint)

$password = ConvertTo-SecureString $certPassword -AsPlainText -Force

Export-PfxCertificate -Cert $cert -FilePath ".\$certificateName.pfx" -Password $password


#upload cert
    #$fileName = "<Path to the .pfx file>"
$fileContentBytes = Get-Content $fileName -Encoding Byte
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
{
  "data": "$filecontentencoded",
  "dataType" :"pfx",
  "password": $certPassword
}
"@

$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded = [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText –Force
Set-AzureKeyVaultSecret -VaultName $vaultName -Name $certPassword -SecretValue $secret


#get the URL
$secretURL = (Get-AzureKeyVaultSecret -VaultName $vaultName -Name $certPassword).Id
Write-Host $secretURL
