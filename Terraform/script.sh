read -p "Insert the Resource Group Name:" RG
read -p "Insert the External IP address to access the container (e.g x.x.x.x/x):" ExternalIP

#clone the script
git clone https://github.com/mahmod-ali29/NC.git
cd NC
git remote remove origin

##Create ACR
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
terraform apply -var-file=variable.tfvars -var="RG=$RG" -var="ExternalIP=$ExternalIP" -auto-approve