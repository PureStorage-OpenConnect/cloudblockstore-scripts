#!/bin/bash
set -e
SHOW_DEBUG_OUTPUT=false
source $(dirname $0)/IaC/parameters.sh

source $(dirname $0)/IaC/script-modules/common.sh


source $(dirname $0)/IaC/script-modules/ascii-logo.sh

echo -e "
------------------------------------------------------------------------------------
   Pure Cloud Block Store - EXAMPLE of agent forwarding metrics into Azure Monitor
                (c) 2024 Pure Storage
                        v$CLI_VERSION
------------------------------------------------------------------------------------
"

# create a RG
echo -e "${C_BLUE3}${C_GREY85}
[Step #1] Create a resource group for monitoring resources:${NO_FORMAT}"
echo "
RG name: $monitoringResourcesRgName
Location: $monitoringResourcesLocation
"
output=$(az group create --name $monitoringResourcesRgName --location $monitoringResourcesLocation)

echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The resource group has been created."
echo ""


# create a vNET
echo -e "${C_BLUE3}${C_GREY85}
[Step #2] Create a vNET ${monitoringResourcesVnetName} for the FunctionApp and PrivateEndpoints:${NO_FORMAT}"
echo "
RG name: $monitoringResourcesRgName
Location: $monitoringResourcesLocation

"

output=$(az deployment group create \
  --name "$monitoringResourcesLocation-DEMO-CBS-Azure-Monitor-Forwarder-bicep-sh-02" \
  --subscription $monitoringResourcesSubscriptionId \
  --resource-group $monitoringResourcesRgName \
  --template-file "IaC/vnet.bicep" \
  --parameters location=$monitoringResourcesLocation vNetName=$monitoringResourcesVnetName
 )

echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment of virtual network has been completed."
echo ""



# deploy FunctionApp, AppInsights, role assignment
echo -e "${C_BLUE3}${C_GREY85}
[Step #3] Deploy a monitoring resources (FunctionApp, KeyVault, Role assignment, AppInsights, etc.):${NO_FORMAT}"
echo "
RG name: $monitoringResourcesRgName
Location: $monitoringResourcesLocation
CBS API Key: $cbsApiKey
"

currentUserId=$( az ad signed-in-user show | jq -r '.id')
myIpAddress=`curl ifconfig.me 2> /dev/null`

output=$(az deployment group create \
  --name "$monitoringResourcesLocation-DEMO-CBS-Azure-Monitor-Forwarder-bicep-sh-03" \
  --subscription $monitoringResourcesSubscriptionId \
  --resource-group $monitoringResourcesRgName \
  --template-file "IaC/monitoring-resources.bicep" \
  --parameters location=$monitoringResourcesLocation monitoringVnetName=$monitoringResourcesVnetName cbsApiKey=$cbsApiKey adminUserPrincipalId=$currentUserId myIpAddress=$myIpAddress
  )

functionAppId=`echo $output | jq -r '.properties.outputs.functionAppId.value'`
functionAppName=`echo $output | jq -r '.properties.outputs.functionAppName.value'`

echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment of function app and associated resources has been completed."
echo ""
# Disable private link service network policies
echo -e "${C_BLUE3}${C_GREY85}
[Step #4]  Disable private link service network policies on the subnet:${NO_FORMAT}"

echo "
CBS subscription: $cbsSubscriptionId
CBS lb name: $cbsLoadBalancerName
CBS managed RG name: $cbsManagedRgName
CBS location: $cbsLocation
CBS name: $cbsName
CBS mgmt LB in: in subnet $cbsVnetLbSubnet in vNET $cbsVnetName in RG $cbsVnetRg"

az network vnet subnet update \
    --name $cbsVnetLbSubnet \
    --vnet-name $cbsVnetName \
    --resource-group $cbsVnetRg \
    --private-link-service-network-policies Disabled
echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment of function app and associated resources has been completed."
echo ""

# create a PrivateLink service for CBS management loadbalancer
echo -e "${C_BLUE3}${C_GREY85}
[Step #5] Create a PrivateLink service and Private Endspoint for CBS mgmt. loadbalancer + update Azure Function config:${NO_FORMAT}"
echo "
Monitoring subscription: $monitoringResourcesSubscriptionId
monitoring RG name: $monitoringResourcesRgName
monitoring location: $monitoringResourcesLocation
monitoring vnet: $monitoringResourcesVnetName

CBS subscription: $cbsSubscriptionId
CBS lb name: $cbsLoadBalancerName
CBS managed RG name: $cbsManagedRgName
CBS location: $cbsLocation
CBS name: $cbsName
"

output=$(
  az deployment group create \
  --name "$monitoringResourcesLocation-DEMO-CBS-Azure-Monitor-Forwarder-bicep-sh-04" \
  --subscription $monitoringResourcesSubscriptionId \
  --resource-group $monitoringResourcesRgName \
  --template-file "IaC/cbs-private-link.bicep" \
  --parameters monitoringSubscriptionId=$monitoringResourcesSubscriptionId monitoringRgName=$monitoringResourcesRgName monitoringVnetName=$monitoringResourcesVnetName monitoringLocation=$monitoringResourcesLocation cbsSubscriptionId=$cbsSubscriptionId cbsManagedRgName=$cbsManagedRgName cbsLocation=$cbsLocation loadBalancerName=$cbsLoadBalancerName
 )

 cbsIpAddressInMonitoringVnet=`echo $output | jq -r '.properties.outputs.cbsIpAddressInMonitoringVnet.value'`

 output=$(
  az deployment group create \
  --name "$monitoringResourcesLocation-DEMO-CBS-Azure-Monitor-Forwarder-bicep-sh-04-appsettings" \
  --subscription $monitoringResourcesSubscriptionId \
  --resource-group $monitoringResourcesRgName \
  --template-file "IaC/func-update-appsettings.bicep" \
  --parameters monitoringSubscriptionId=$monitoringResourcesSubscriptionId monitoringRgName=$monitoringResourcesRgName monitoringLocation=$monitoringResourcesLocation funcAppName=$functionAppName cbsIpAddressInMonitoringVnet=$cbsIpAddressInMonitoringVnet
 )

echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment of private link resources has been completed."
echo ""

# deploy a code from ./FunctionApp/ folder into the FunctionApp
echo -e "${C_BLUE3}${C_GREY85}
[Step #6] Deploy a code into FunctionApp:${NO_FORMAT}"
echo "
Monitoring subscription: $monitoringResourcesSubscriptionId
RG name: $monitoringResourcesRgName
Location: $monitoringResourcesLocation
FunctionApp name: $functionAppName
"

originDir=$PWD

echo "Building and publishing solution"
# Build and publish the solution
cd "FunctionApp"
 func azure functionapp publish $functionAppName
cd "${originDir}"


echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment has been completed."
echo ""





# create a Azure Monitor dashboard
echo -e "${C_BLUE3}${C_GREY85}
[Step #7] Create an Azure Monitor dashboard:${NO_FORMAT}"
echo "
FunctionApp id: $functionAppId
"
 az deployment group create \
  --name "$monitoringResourcesLocation-DEMO-CBS-Azure-Monitor-Forwarder-bicep-sh-05-dashboard" \
  --subscription $monitoringResourcesSubscriptionId \
  --resource-group $monitoringResourcesRgName \
  --template-file "IaC/dashboard.bicep" \
  --parameters dashboardName=mycbs-dashboard location=$monitoringResourcesLocation functionAppId=$functionAppId
 

echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment has been completed."
echo ""

