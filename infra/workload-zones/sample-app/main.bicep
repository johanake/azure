// ---------------------------------------------------------------------------
// WORKLOAD ZONE — sample-app
// SCOPE:   subscription (deploy into the workload subscription under <prefix>-corp)
//
// This is what an application team owns: its own resource group(s) and the
// resources the app needs. It inherits policy/RBAC from the management groups
// above it and reuses the shared modules in infra/modules.
//
// Copy this folder to add another workload (e.g. workload-zones/billing-api).
//
// Deploy:
//   az account set --subscription <workload-subscription-id>
//   az deployment sub create \
//     --location swedencentral \
//     --parameters dev.bicepparam
// ---------------------------------------------------------------------------
targetScope = 'subscription'

param location string = deployment().location

@description('Short environment name.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Workload name used in resource names.')
@minLength(2)
@maxLength(10)
param workloadName string

param tags object = {}

var commonTags = union(tags, {
  environment: environment
  workload: workloadName
  managedBy: 'bicep'
  zone: 'workload'
})

var resourceGroupName = 'rg-${workloadName}-${environment}-${location}'

module rg '../../modules/resource-group.bicep' = {
  name: 'rg-${workloadName}-${environment}'
  params: {
    name: resourceGroupName
    location: location
    tags: commonTags
  }
}

module storage '../../modules/storage.bicep' = {
  name: 'st-${workloadName}-${environment}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg]
  params: {
    location: location
    // Storage names must be globally unique, 3-24 lowercase alphanumerics.
    // uniqueString() gives a stable hash so redeploys produce the same name.
    name: take(toLower('st${workloadName}${environment}${uniqueString(subscription().id, workloadName)}'), 24)
    tags: commonTags
  }
}

output resourceGroupName string = rg.outputs.name
output storageAccountName string = storage.outputs.name
