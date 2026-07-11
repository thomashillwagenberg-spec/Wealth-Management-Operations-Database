#!/usr/bin/env bash
set -euo pipefail
: "${AZURE_SUBSCRIPTION_ID:?Required}"
: "${AZURE_RESOURCE_GROUP:?Required}"
: "${AZURE_LOCATION:?Required}"
profile="${1:-dev}"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"
az deployment group what-if --resource-group "$AZURE_RESOURCE_GROUP" --parameters "infra/bicep/parameters/${profile}.bicepparam"
az deployment group create --resource-group "$AZURE_RESOURCE_GROUP" --parameters "infra/bicep/parameters/${profile}.bicepparam" --name "wmops-${profile}-$(date +%Y%m%d%H%M%S)"
