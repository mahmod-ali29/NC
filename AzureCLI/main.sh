#!/bin/bash
read -p "Insert the External Subnet to access the Linux Container (e.g.89.1.208.203):" ExternalIP
RG="1-c38f8b22-playground-sandbox"
region1="eastus"
region2="centralus"
storageAccountName="storageaccounttest1s112as"
webapp1="appghostblog-2342-${region1}"
webapp2="appghostblog-2442-${region2}"

#create storage account
az storage account create \
 --name $storageAccountName \
 --resource-group $RG \
 --location $region1 \
 --sku Standard_RAGRS

#create file share for ghost blog app
az storage share create \
--account-name $storageAccountName \
--name ghost-fileshare 

AccessKey=$(az storage account keys list --account-name $storageAccountName --query [0].value)

##Create a custom Image container
az acr create \
	--resource-group $RG \
	--location $region1 \
	--name acrbuildcontainer11 \
	--sku Basic \
	--admin-enabled true
 
az acr build \
	--image ghost/ghost-alpine:v1 \
	--registry acrbuildcontainer11 \
	--file Dockerfile . 

#Create App Service Plan for region1 & region2
az appservice plan create \
	--name "AppServicePlan-${region1}" \
	--location $region1 \
	--resource-group $RG \
	--sku S1 \
	--is-linux

az appservice plan create \
	--name "AppServicePlan-${region2}" \
	--location $region2 \
	--resource-group $RG \
	--sku S1 \
	--is-linux
   
#Create Autoscaling Rules for region1 & region2
az monitor autoscale create \
	--resource-group $RG \
	--resource "AppServicePlan-${region1}" \
	--min-count 2 \
	--max-count 8 \
	--count 2 \
	--resource-type Microsoft.Web/serverfarms \
    --email-administrator true

az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region1}" \
	--scale out 6 \
	--condition "CpuPercentage > 75 avg 5m"

az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region1}" \
	--scale out 6 \
	--condition "SocketInboundAll > 200 avg 5m"

az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region1}" \
	--scale in 6 \
	--condition "CpuPercentage < 75 avg 5m"
az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region1}" \
	--scale in 6 \
	--condition "SocketInboundAll < 200 avg 5m"

az monitor autoscale create \
	--resource-group $RG \
	--resource "AppServicePlan-${region2}" \
	--min-count 2 \
	--max-count 8 \
	--count 2 \
	--resource-type Microsoft.Web/serverfarms \
    --email-administrator true

az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region2}" \
	--scale out 6 \
	--condition "CpuPercentage > 70 avg 5m"

az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region2}" \
	--scale out 6 \
	--condition "SocketInboundAll > 200 avg 5m"

az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region2}" \
	--scale in 6 \
	--condition "CpuPercentage < 70 avg 5m"
az monitor autoscale rule create \
	--resource-group $RG \
	--autoscale-name "AppServicePlan-${region2}" \
	--scale in 6 \
	--condition "SocketInboundAll < 200 avg 5m"

#Create Web App for region1 & region2	
az webapp create \
	--resource-group $RG \
	--plan "AppServicePlan-${region1}" \
	--name $webapp1 \
	--deployment-container-image-name acrbuildcontainer11.azurecr.io/ghost/ghost-alpine:v1 \
    --https-only true

az webapp create \
	--resource-group $RG \
	--plan "AppServicePlan-${region2}" \
	--name $webapp2 \
	--deployment-container-image-name acrbuildcontainer11.azurecr.io/ghost/ghost-alpine:v1 \
    --https-only true

#Enable Application and Container Logging for region1 & region2
az webapp log config \
	--resource-group $RG \
	--name $webapp1 \
	--application-logging filesystem \
	--docker-container-logging filesystem \
	--web-server-logging filesystem

az webapp log config \
	--resource-group $RG \
	--name $webapp2 \
	--application-logging filesystem \
	--docker-container-logging filesystem \
	--web-server-logging filesystem

#configure App Healthcheck for region1 & region2
az webapp config set \
	--resource-group $RG \
	--name $webapp1 \
	--generic-configurations '{"healthCheckPath":"/"}' \
	--ftps-state FtpsOnly

az webapp config appsettings set \
	--resource-group $RG \
	--name $webapp1 \
	--settings WEBSITE_HEALTHCHECK_MAXPINGFAILURES=2

az webapp config set \
	--resource-group $RG \
	--name $webapp2 \
	--generic-configurations '{"healthCheckPath":"/"}' \
	--ftps-state FtpsOnly

az webapp config appsettings set \
	--resource-group $RG \
	--name $webapp2 \
	--settings WEBSITE_HEALTHCHECK_MAXPINGFAILURES=2

#Create stagging deployment Slot for App1 in region1 & region2
az webapp deployment slot create \
	--name $webapp1 \
	--resource-group $RG \
	--slot testing

az webapp deployment slot create \
	--name $webapp2 \
	--resource-group $RG \
	--slot testing

#####Create Frontdoor using ARM template#######
az deployment group create \
	--resource-group $RG \
	--template-file azuredeploy.json \
    --parameters frontDoorName="ghostblogafd" backendAddress="$webapp1.azurewebsites.net" backendAddress2="$webapp2.azurewebsites.net"

#Create WAF policy and associate it to the frontdoor
az extension add --name front-door

az network front-door waf-policy create \
--resource-group $RG \
--sku "Classic_AzureFrontDoor" \
--name "WAFpolicy" \
--mode "Prevention" \
--disabled false

az network front-door waf-policy managed-rules add \
--policy-name "WAFpolicy" \
--resource-group $RG \
--type "Microsoft_DefaultRuleSet" \
--version "1.1"

WAFpolicyID=$(az network front-door waf-policy show -g $RG -n WAFpolicy --query "[id]" --output tsv)

az network front-door update \
--name ghostblogafd \
--resource-group $RG \
--set FrontendEndpoints[0].WebApplicationFirewallPolicyLink.id=$WAFpolicyID

#Blocking direct access to the App via https, allow only from the frontdoor
az webapp config access-restriction add \
	--resource-group $RG \
	--name $webapp1 \
    --rule-name allow-frontdoor \
    --action Allow \
    --service-tag AzureFrontDoor.Backend \
    --priority 10

az webapp config access-restriction add \
	--resource-group $RG \
	--name $webapp2 \
    --rule-name allow-frontdoor \
    --action Allow \
    --service-tag AzureFrontDoor.Backend \
    --priority 10

#Blocking direct access to the App via ssh, allow only from the your External IP Address
 az webapp config access-restriction add \
	--resource-group $RG \
	--name $webapp1 \
    --rule-name allow-frontdoor \
    --action Allow \
    --scm-site true \
    --ip-address $ExternalIP \
    --priority 10

az webapp config access-restriction add \
	--resource-group $RG \
	--name $webapp2 \
    --rule-name allow-frontdoor \
    --action Allow \
    --scm-site true \
    --ip-address $ExternalIP \
    --priority 10

#Create Log Analytics 
az monitor log-analytics workspace create \
    -g $RG \
    -n ghostblogLogWorkspace

#Add Application Insights extension
az extension add --name application-insights

#Enable Application Insights on App1 and App2
az monitor app-insights component create \
--resource-group $RG \
--app AppInsight \
--location $region1 \
--kind web \
--application-type web \
--retention-time 120

az monitor app-insights component connect-webapp \
--resource-group $RG \
--app AppInsight \
--web-app $webapp1 \
--enable-debugger false \
--enable-profiler false

az monitor app-insights component connect-webapp \
--resource-group $RG \
--app AppInsight \
--web-app $webapp2 \
--enable-debugger false \
--enable-profiler false

IDApp1=$(az webapp show --resource-group $RG --name $webapp1 --query [id] --output tsv)
IDApp2=$(az webapp show --resource-group $RG --name $webapp2 --query [id] --output tsv)

#Export Diagnostic settings to Log Analytics Workspace for App1
az monitor diagnostic-settings create \
--resource-group $RG \
--resource $IDApp1 \
--name "diag-$webapp1" \
--export-to-resource-specific true \
--workspace "ghostblogLogWorkspace" \
--logs '[
     {
       "category": "AppServiceHTTPLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceConsoleLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceAppLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceAuditLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceIPSecAuditLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServicePlatformLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     }	 	 	 	 	 
   ]' \
--metrics '[
     {
       "category": "AllMetrics",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     }
   ]'

#Export Diagnostic settings to Log Analytics Workspace for App2
az monitor diagnostic-settings create \
--resource-group $RG \
--resource $IDApp2 \
--name "diag-$webapp2" \
--export-to-resource-specific true \
--workspace "ghostblogLogWorkspace" \
--logs '[
     {
       "category": "AppServiceHTTPLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceConsoleLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceAppLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceAuditLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServiceIPSecAuditLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     },
     {
       "category": "AppServicePlatformLogs",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     }	 	 	 	 	 
   ]' \
--metrics '[
     {
       "category": "AllMetrics",
       "enabled": true,
       "retentionPolicy": {
         "enabled": false,
         "days": 0
       }
     }
   ]'  


#Output
URL=$(az network front-door frontend-endpoint show -g $RG --name "frontEndEndpoint" --front-door-name "ghostblogafd" --query "[hostName]"  --output tsv)
echo "Ghost Blog URL: https://$URL"
