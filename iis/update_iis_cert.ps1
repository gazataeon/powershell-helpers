# This mad little script will make sure your new Cert in all the right places and update any IIS binding using the old one

Import-Module WebAdministration

$oldhash = "EBxxxxxxxxxxxxxxxxxxxxxx721"
$newhash = "EBxxxxxxxxxxxxxxxxxxxxxx722" # this needs updating lol

$pfxPass = "?????" # this too
$pfxLocation = "c:\temp\certs\google.com.pfx" # check this ofc

$bindings 

$newcert = Get-ChildItem -Path Cert:\LocalMachine\My | where-Object {$_.Thumbprint -like $newhash} | Select-Object -ExpandProperty Thumbprint

# Import Cert
function Import-GazPfxCertificate {
    param 
    (
        [String]$certPath,
        [String]$certRootStore = "LocalMachine",
        [String]$certStore = "TrustedPeople"
    )

    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
    $pfx.import($certPath,$pfxPass,"Exportable,MachineKeySet,PersistKeySet")
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
    $store.open("MaxAllowed")
    $store.add($pfx)
    $store.close()
}

Import-GazPfxCertificate -certPath $pfxLocation
Import-GazPfxCertificate -certPath $pfxLocation -certRootStore "CurrentUser" -certStore "My"
Import-GazPfxCertificate -certPath $pfxLocation -certStore "My"


#Replace cert
foreach ($binding in $bindings)
{
if ($binding.certificateHash -ne $null){$siteCertHashStr = $binding.certificatehash.ToString()}
write-host "checking site :$($binding.bindingInformation.ToString())"
    if ($binding.certificatehash -eq $oldhash)
    {
        $sitename = $binding.ItemXPath
        $sitename = $sitename -replace ".\w*.\w*.\w*.\w*.(@name=')"
        $sitename = $sitename -replace "'\sand\s@id='\d']"
        $fqdn = $binding.bindingInformation.split(':').item(2)
        $ipaddress = $binding.bindingInformation.split(':').item(0)
      
        write-host "Updating Binding: $sitename" -ForegroundColor Green
	    $binding | remove-webbinding
        New-WebBinding -Name $sitename -Port 443 -Protocol https -HostHeader $fqdn -IPAddress $ipaddress
	(Get-WebBinding -Name $sitename -Port 443 -Protocol "https" -HostHeader $fqdn).AddSslCertificate($newcert, "my") 
    }
    else
    {
        write-host "skipping $($binding.bindingInformation.ToString())" -ForegroundColor yellow
    }
}


