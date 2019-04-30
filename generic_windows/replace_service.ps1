 # Description: Find Service, Stop it, Delete it, recreate it
 # Handy for deployments
 
 
 #Declare service names
 $servicename = "Application Service Name"
 
 #check to see if exists
if ($varservice = Get-Service $servicename -ErrorAction SilentlyContinue) {
    #if it does then is it stopped?
    if ($varservice.Status -ne "Running"){
    $objservice = Get-WmiObject -Class Win32_Service -Filter Name="'$servicename'"
    $objservice.delete()
    }
    if ($varservice.Status -eq "running"){ 
    Stop-Service $servicename
    $objservice = Get-WmiObject -Class Win32_Service -Filter Name="'$servicename'"
    $objservice.delete()
    }
 }
 else
 {
 New-Service -Name "Application Service Name" -BinaryPathName "d:\services\project\service.exe"
 }