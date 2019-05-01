############################
# Script to Create a Self signed Cert to be used for a new service principle authentication
# 
############################



#Creates a self signed cert for 3 years

$certName = Read-Host -Prompt "enter cert name"
$spName = Read-Host -Prompt "enter service principle name"

$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" `
  -Subject "CN=$($certName)" `
  -KeySpec KeyExchange -NotAfter (get-date).AddYears(3)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

#export the cert as base64 to C:\temp\sp_cert.cer

$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate 
$cer.Import("C:\temp\sp_cert.cer") 
$binCert = $cer.GetRawCertData() 
$credValue = [System.Convert]::ToBase64String($binCert)
New-AzureRmADSpCredential -ServicePrincipalName "http://$($spName)" -CertValue $credValue


#view current ones
Get-AzureRmADSpCredential -ServicePrincipalName "http://$($spName)"



# use this to remove existing ones
#Remove-AzureRmADSpCredential -ServicePrincipalName http://jenkins_sp -KeyId 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'