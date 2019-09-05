#Make a new Root cert
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=eu-w-system-vnet-gw-5y_root" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign -NotAfter (Get-Date).AddMonths(48)

#OR

# use existing 
Get-ChildItem -Path "Cert:\CurrentUser\My\" # find your cert thumb
$certThumb = "put it here"
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$($certThumb)" # then this


#THEN!!!!!!!!

#Child Cert
New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=eu-w-system-vnet-gw-child" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") -NotAfter (Get-Date).AddMonths(24)
#set for 2 year