// ---------------------------------------------------------------------------
// MODULE: Subscription
// SCOPE:  managementGroup
//
// Two modes:
//   1. billingScope set   -> CREATE a new subscription (subscription alias) and
//                            place it in the management group. Requires an EA or
//                            MCA billing account and permission on it.
//   2. existingSubscriptionId set -> MOVE an existing subscription into the
//                            management group. Works for any subscription type
//                            (pay-as-you-go, Visual Studio, etc.).
// ---------------------------------------------------------------------------
targetScope = 'managementGroup'

@description('Management group the subscription should live in.')
param managementGroupName string

@description('Subscription display name (only used when creating).')
param displayName string = ''

@description('Billing scope resource ID for creating a new subscription. Leave empty to use an existing subscription.')
param billingScope string = ''

@description('Existing subscription ID to place in the management group. Used when billingScope is empty.')
param existingSubscriptionId string = ''

@allowed([
  'Production'
  'DevTest'
])
param workload string = 'Production'

var createNew = !empty(billingScope)

// Mode 1: create a new subscription.
// An "alias" is the Azure resource that represents a subscription request.
resource alias 'Microsoft.Subscription/aliases@2021-10-01' = if (createNew) {
  scope: tenant()
  name: replace(toLower(displayName), ' ', '-')
  properties: {
    displayName: displayName
    billingScope: billingScope
    workload: workload
    additionalProperties: {
      managementGroupId: tenantResourceId('Microsoft.Management/managementGroups', managementGroupName)
    }
  }
}

// Mode 2: place an existing subscription.
// `existing` means "reference something already deployed, don't create it".
resource managementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: managementGroupName
}

resource placement 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = if (!createNew) {
  parent: managementGroup
  name: existingSubscriptionId
}

output subscriptionId string = createNew ? alias!.properties.subscriptionId : existingSubscriptionId
