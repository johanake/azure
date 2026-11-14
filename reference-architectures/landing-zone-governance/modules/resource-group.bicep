// ---------------------------------------------------------------------------
// MODULE: Resource group
// SCOPE:  subscription  (resource groups live inside a subscription)
// ---------------------------------------------------------------------------
targetScope = 'subscription'

@description('Resource group name, e.g. rg-<workload>-<env>-<region>.')
param name string

@description('Azure region for the resource group metadata.')
param location string

@description('Resource tags.')
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: name
  location: location
  tags: tags
}

output name string = resourceGroup.name
output id string = resourceGroup.id
