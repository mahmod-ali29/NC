read -p "Insert the Resource Group Name:" RG
storageAccountName="storageghostblog$RANDOM"

#Get  your External IP address
ExternalIP=$(curl -s ipinfo.io/ip)

#Create ACR
az acr create \
        --resource-group $RG \
        --name acrbuildcontainer11 \
        --sku Basic \
        --admin-enabled true

#Build image and push it to ACR
az acr build \
        --image ghost/ghost-alpine:v1 \
        --registry acrbuildcontainer11 \
        --file Dockerfile . 

#Run terraform script
terraform init
terraform apply -var-file=variable.tfvars -var="RG=$RG" -var="ExternalIP=$ExternalIP" -var="storageAccountName=$storageAccountName" -auto-approve
