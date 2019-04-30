#You need to capture the thumbprint of the installed certificate:
$CertShop=Get-ChildItem -Path Cert:\LocalMachine\My | 
where-Object {$_.subject -like "*aeon-it.co.uk*"} | 
Select-Object -ExpandProperty Thumbprint

#The WebAdministration module provides access to the IIS drive, which allows you to modify the SSL bindings:
Import-Module WebAdministration

#The next step is to remove the existing binding from the IP address:
Get-Item IIS:\SslBindings\10.0.0.4!443 | Remove-Item

#And finally, update the SSL binding to use the new certificate:
get-item -Path "cert:\LocalMachine\My\$certShop" | 
new-item -path IIS:\SslBindings\10.0.0.4!443


#_________________________________________________________________
#THE ABOVE DONE WORK GOOD?
#TRY THIS!

$binding = (Get-WebBinding -Name "default web site" | where-object {$_.protocol -eq "https"})
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | where-Object {$_.subject -like "*aeon-it.co.uk*"} | Select-Object -ExpandProperty Thumbprint
if($binding -ne $null) {
    Remove-WebBinding -Name "default web site" -Port 443 -Protocol "https" -HostHeader $fqdn
} 
New-WebBinding -Name "default web site" -Port 443 -Protocol https -HostHeader $fqdn 
(Get-WebBinding -Name "default web site" -Port 443 -Protocol "https" -HostHeader $fqdn).AddSslCertificate($cert, "my")