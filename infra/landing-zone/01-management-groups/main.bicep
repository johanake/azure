// ---------------------------------------------------------------------------
// STEP 1 — Management group hierarchy (platform landing zone)
// SCOPE:   managementGroup (deploy at the Tenant Root Group)
//
// Builds a small version of the Cloud Adoption Framework hierarchy:
//
//   Tenant Root Group
//   └── <prefix>                    intermediate root, put org-wide policy here
//       ├── <prefix>-platform       shared platform services
//       │   └── <prefix>-management     logging / monitoring subscription
//       └── <prefix>-landingzones   where application workloads live
//           └── <prefix>-corp           internal (corp-connected) workloads
//
// Deploy:
//   az deployment mg create \
//     --management-group-id <tenant-id> \
//     --location swedencentral \
//     --parameters main.bicepparam
// ---------------------------------------------------------------------------
targetScope = 'managementGroup'

@description('Prefix for management group IDs, e.g. your company short name.')
param prefix string

@description('Parent of the hierarchy. Defaults to the Tenant Root Group (its ID equals the tenant ID).')
param rootParentId string = tenant().tenantId

// Each module gets a `name` — that is the *deployment* name you'll see in the
// portal under "Deployments", not the resource name.

module root '../../modules/management-group.bicep' = {
  name: 'mg-${prefix}'
  params: {
    name: prefix
    displayName: prefix
    parentId: rootParentId
  }
}

module platform '../../modules/management-group.bicep' = {
  name: 'mg-${prefix}-platform'
  params: {
    name: '${prefix}-platform'
    displayName: 'Platform'
    // Referencing root.outputs creates an implicit dependency:
    // Bicep waits for `root` before deploying this one.
    parentId: root.outputs.name
  }
}

module management '../../modules/management-group.bicep' = {
  name: 'mg-${prefix}-management'
  params: {
    name: '${prefix}-management'
    displayName: 'Management'
    parentId: platform.outputs.name
  }
}

module landingZones '../../modules/management-group.bicep' = {
  name: 'mg-${prefix}-landingzones'
  params: {
    name: '${prefix}-landingzones'
    displayName: 'Landing Zones'
    parentId: root.outputs.name
  }
}

module corp '../../modules/management-group.bicep' = {
  name: 'mg-${prefix}-corp'
  params: {
    name: '${prefix}-corp'
    displayName: 'Corp'
    parentId: landingZones.outputs.name
  }
}

output managementGroups object = {
  root: root.outputs.name
  platform: platform.outputs.name
  management: management.outputs.name
  landingZones: landingZones.outputs.name
  corp: corp.outputs.name
}
