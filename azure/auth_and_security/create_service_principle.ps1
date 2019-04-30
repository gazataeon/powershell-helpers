## This really needs some work.

Login-AzureRmAccount
$sp = New-AzureRmADServicePrincipal -DisplayName my_spname -Password "helloThere"
Sleep 20
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId



$sp_pass = ConvertTo-SecureString -AsPlainText -Force "helloThere" 
$sp_appID = "xxxxxxxx"
$sp_obid = "xxxxxxx"
$cred = New-Object PSCredential  $sp_appID, $sp_pass
Login-AzureRmAccount -Credential $cred -ServicePrincipal -TenantId "xxxxxxxxxxxxxxxxxxxx"


Get-AzureRmADSpCredential -ObjectId "xxxxxxxxxxxxxx"
New-AzureRmADSpCredential -ObjectId "xxxxxxxxxxxxxx" -Password "helloThere"


