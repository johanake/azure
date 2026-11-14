// ---------------------------------------------------------------------------
// MODULE: Management group
// SCOPE:  managementGroup  (the deployment runs at a management group, but the
//         management group *resource* itself lives at the tenant, hence
//         `scope: tenant()` below)
//
// A management group is a folder for subscriptions. Policies and RBAC assigned
// to a management group are inherited by everything beneath it.
// ---------------------------------------------------------------------------
targetScope = 'managementGroup'

@description('Management group ID (the name in the resource ID). Cannot be changed later.')
@maxLength(90)
param name string

@description('Friendly name shown in the portal.')
param displayName string

@description('ID of the parent management group. Use the tenant ID to place it directly under Tenant Root Group.')
param parentId string

resource managementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: name
  properties: {
    displayName: displayName
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', parentId)
      }
    }
  }
}

output id string = managementGroup.id
output name string = managementGroup.name
