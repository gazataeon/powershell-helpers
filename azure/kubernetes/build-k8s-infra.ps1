# note: passwords have been removed and are replaced with XXXXXXXXXXXXXXXX

#login to az
az login
az account set --subscription "Your Azure Sub Name Here"

#user defined stuff
$locationName = "westeurope"
$rgPrefix = "eu-w-k8s-"
$stagingRg = "$($rgPrefix)staging-rg"
$liveRg = "$($rgPrefix)live-rg"
$manRg = "$($rgPrefix)management-rg"
$acrName = "myacrname"
$sp_man = "sp_k8sman"
$sp_live = "sp_k8slive"
$sp_staging = "sp_k8sstaging"
$aksLiveName = "liveaks"
$aksStagingName = "stagingaks"
$stagingPipName = "eu-w-k8s-staging-platform1-pip" # platform1 write whatever you wanna name your first service, this will be refferenced in the yml later
$livePipName = "eu-w-k8s-live-platform1-pip" # platform1 write whatever you wanna name your first service, this will be refferenced in the yml later

#make RGs
az group create --name $manRg --$locationName  
az group create --name $liveRg --location $locationName 
az group create --name $stagingRg --location $locationName 

#make container registry
az acr create --resource-group $manRg --name $acrName --sku Premium --admin-enabled true

#login to registry (do this for both)
az acr login --name $acrName

#Get registry URL - format example : k8smainacr.azurecr.io
$acrUrl = az acr list --resource-group $manRg --query "[].{acrLoginServer:loginServer}" --output table
$acrUrl = $acrUrl[2]
write-host $acrUrl -ForegroundColor Green

# Enable admin Docker username and password login style for ACR
az acr update -n $acrName --admin-enabled true
az acr credential show --name $acrName # Show passwords after this

#test with docker login (username is container name)
docker login $acrUrl -u $acrName 

#list images in repo (test, should be empty)
az acr repository list --name $acrName --output table

#---------------------------------------------------------------
##Deploy Azure Kubernetes Service (AKS) clusters

#Create service principals 
$sp_manInfo = az ad sp create-for-rbac --skip-assignment --name $sp_man --password XXXXXXXXXXXXXXXX  ##Pushing Images and any managment services
$sp_liveInfo = az ad sp create-for-rbac --skip-assignment --name $sp_live --password XXXXXXXXXXXXXXXX    ##live AKS deployments
$sp_stagingInfo = az ad sp create-for-rbac --skip-assignment --name $sp_staging --password XXXXXXXXXXXXXXXX  ##Staging AKS deployments

#Output info - RECORD THIS IN PASSWORD SAFE!!!!
$sp_manInfo = $sp_manInfo | ConvertFrom-Json
$sp_liveInfo = $sp_liveInfo | ConvertFrom-Json
$sp_stagingInfo = $sp_stagingInfo | ConvertFrom-Json
Write-Host $sp_manInfo | ConvertFrom-Json -ForegroundColor orange
Write-Host $sp_liveInfo | ConvertFrom-Json -ForegroundColor orange
Write-Host $sp_stagingInfo | ConvertFrom-Json -ForegroundColor orange


#Configure ACR authentication (assignee is your appID) 
#get ACR ID
$acrID = az acr show --resource-group $manRg --name $acrName --query "id" --output tsv
Write-Host $acrID 

#Grant access to from AKS SPs to the ACR
az role assignment create --assignee $sp_manInfo.appId --scope $acrID --role contributor
az role assignment create --assignee $sp_liveInfo.appId --scope $acrID --role contributor
az role assignment create --assignee $sp_stagingInfo.appId --scope $acrID --role contributor


# Create Kubernetes clusters (service-principal = appID, secret = password )
az aks create --resource-group $stagingRg --name $aksStagingName --node-count 3 --service-principal $sp_liveInfo.appID --client-secret $sp_liveInfo.password --generate-ssh-keys
az aks create --resource-group $liveRg --name $aksStagingName --node-count 3 --service-principal $sp_stagingInfo.appID --client-secret $sp_stagingInfo.password --generate-ssh-keys

#connect to cluster(s)
az aks get-credentials --resource-group $liveRg --name $aksLiveName
az aks get-credentials --resource-group $stagingRg --name $aksStagingName

#PUBLIC IP CREATION -- note these IPs because you need to make your DNS records with them later
az network public-ip create --resource-group $stagingRg --name $stagingPipName --allocation-method static
az network public-ip create --resource-group $liveRg --name $livePipName --allocation-method static

