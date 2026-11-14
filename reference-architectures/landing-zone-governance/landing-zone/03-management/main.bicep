// ---------------------------------------------------------------------------
// STEP 3 — Shared platform services (management subscription)
// SCOPE:   subscription (deploy into the management subscription)
//
// Creates a resource group and a central Log Analytics workspace that every
// workload can send its logs to.
//
// Deploy:
//   az account set --subscription <management-subscription-id>
//   az deployment sub create \
//     --location swedencentral \
//     --parameters main.bicepparam
// ---------------------------------------------------------------------------
targetScope = 'subscription'

param location string = deployment().location

@description('Prefix used in resource names.')
param prefix string

param tags object = {}

var commonTags = union(tags, {
  managedBy: 'bicep'
  zone: 'platform'
})

// `scope:` must be known when the deployment starts, so compute the RG name
// up front instead of reading it from rg.outputs.
var resourceGroupName = 'rg-${prefix}-management-${location}'

module rg '../../modules/resource-group.bicep' = {
  name: 'rg-${prefix}-management'
  params: {
    name: resourceGroupName
    location: location
    tags: commonTags
  }
}

// A subscription-scoped file can't deploy resources directly into a resource
// group — it hands off to a module and sets `scope: resourceGroup(...)`.
module logs '../../modules/log-analytics.bicep' = {
  name: 'log-${prefix}-management'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg] // explicit dependency, since we no longer reference rg.outputs
  params: {
    name: 'log-${prefix}-management-${location}'
    location: location
    tags: commonTags
  }
}

output logAnalyticsWorkspaceId string = logs.outputs.id
