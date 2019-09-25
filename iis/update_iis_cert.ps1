#################################################################################################################################################################
### This mad little script will make sure your new Cert in all the right places and update any IIS binding using the old one 
#**     You'll notice it only updates one cert initally, thats because any other bindings that dont use SNI will be updated automatically too. 
#**     Additional runs should pick up any sites that use SNI. Feel free up adjust the last part with a loop if you like! 
#################################################################################################################################################################

Import-Module WebAdministration
$ErrorActionPreference = "Stop"

## Variables ##
$oldhash = "G16C16CE1539316CE1539316CE1539316CE15391" # find this with "Get-ChildItem -path cert:\LocalMachine\My"
$newhash = "G16C16CE1539316CE1539316CE1539316CE15392" # 

$pfxPass = "GeneralKenobi1234" # 
$pfxLocation = "C:\Users\gazataeon\Downloads\gazataeon.com.pfx" # 

## Functions ##
function Import-GazPfxCertificate 
{
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

## Body ##
Write-host "Importing the PFX to the cert stores." -ForegroundColor Yellow
Import-GazPfxCertificate -certPath $pfxLocation
Import-GazPfxCertificate -certPath $pfxLocation -certRootStore "CurrentUser" -certStore "My"
Import-GazPfxCertificate -certPath $pfxLocation -certStore "My"
$newcert = Get-ChildItem -Path Cert:\LocalMachine\My | where-Object {$_.Thumbprint -like $newhash} | Select-Object -ExpandProperty Thumbprint
Write-host "Cert Imported! Let's update IIS now!" -ForegroundColor Green

write-host "Checking for IIS sites that use the old Cert Hash" -ForegroundColor Yellow
$bindings = Get-WebBinding 
[array]$hashlist = $null
foreach($certHashItem in ($bindings | Select-Object certificateHash)){
$hashList += $certHashItem.certificateHash
}

# Check if there is an old hash in use?
if ($hashList.Contains($oldhash))
{
    $oldBindings = $bindings | Where-Object certificateHash -eq $oldhash
    write-host "Found $($oldBindings.count) bindings that use the old hash!" -ForegroundColor Yellow
    #Update one binding first
    $bindingToUpdate = $oldBindings | Select-Object * -First 1

    $sitename = $bindingToUpdate.ItemXPath
    $sitename = $sitename -replace ".\w*.\w*.\w*.\w*.(@name=')"
    $sitename = $sitename -replace "'\sand\s@id='\d']"
    $fqdn = $bindingToUpdate.bindingInformation.split(':').item(2)
    $ipaddress = $bindingToUpdate.bindingInformation.split(':').item(0)
    write-host "Updating $($sitename) first " -ForegroundColor Yellow

    write-host "Removing Old Binding: $sitename" -ForegroundColor Yellow
    $bindingToUpdate | remove-webbinding

    write-host "adding new Binding: $sitename" -ForegroundColor Yellow
    New-WebBinding -Name $sitename -Port 443 -Protocol https -HostHeader $fqdn -IPAddress $ipaddress
    (Get-WebBinding -Name $sitename -Port 443 -Protocol "https" -HostHeader $fqdn).AddSslCertificate($newcert, "my") 
}
write-host "Re checking bindings to make sure they all updated" -ForegroundColor Yellow
$bindings = Get-WebBinding 
[array]$hashlist = $null
foreach($certHashItem in ($bindings | Select-Object certificateHash))
{
$hashList += $certHashItem.certificateHash
}

# is there an old hash in use?
if ($hashList.Contains($oldhash))
{
Write-host "Looks like there's a site still using the old hash!, rerun this and it should clear up. If not, seek a Doctor." -ForegroundColor red
$bindings | Where-Object certificateHash -Like $oldhash
}
else
{ write-host "No old hashes found!" -ForegroundColor Green }