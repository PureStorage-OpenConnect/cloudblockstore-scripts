#!/bin/bash
set -e
SHOW_DEBUG_OUTPUT=false
source $(dirname $0)/IaC/parameters.sh

source $(dirname $0)/IaC/script-modules/common.sh


source $(dirname $0)/IaC/script-modules/ascii-logo.sh

echo -e "
------------------------------------------------------------------------------------
   Pure Cloud Block Store - Sample of agent forwarding metrics into Azure Monitor
                (c) 2024 Pure Storage
                        v$CLI_VERSION
------------------------------------------------------------------------------------
"


output=$(az deployment group create \
  --name "$location-DEMO-CBS-Azure-Monitor-variables" \
  --subscription $monitoringResourcesSubscriptionId \
  --resource-group $monitoringResourcesRgName \
  --template-file "IaC/bicep-modules/variables.bicep"
 )

functionAppName=`echo $output | jq -r '.properties.outputs.monitoringFunctionAppName.value'`

originDir=$PWD

echo -e "${C_BLUE3}${C_GREY85}
[Step #1] Publish new version of FunctionApp:${NO_FORMAT}"
echo "
Monitoring subscription: $monitoringResourcesSubscriptionId
monitoring RG name: $monitoringResourcesRgName
monitoring location: $monitoringResourcesLocation
FunctionApp: $functionAppName

"
# Build and publish the solution
cd "./FunctionApp"
 func azure functionapp publish $functionAppName
cd "${originDir}"


echo ""
echo ""
echo ""
echosuccess "[STEP COMPLETED] The deployment has been completed."
echo ""

