// ---------------------------------------------------------------------------
// STEP 2 — Subscriptions (a.k.a. "subscription vending")
// SCOPE:   managementGroup (deploy at the <prefix> intermediate root)
//
// Places one subscription in each branch of the hierarchy:
//   <prefix>-management  <- management subscription (platform)
//   <prefix>-corp        <- workload subscription   (application landing zone)
//
// For each of the two you choose one of:
//   - give its ...SubscriptionId  -> an EXISTING subscription is moved in
//   - give its ...SubscriptionName (and billingScope) -> a NEW one is created
//
// Deploy:
//   az deployment mg create \
//     --management-group-id az \
//     --location swedencentral \
//     --parameters main.bicepparam
// ---------------------------------------------------------------------------
targetScope = 'managementGroup'

@description('Prefix used in step 1.')
param prefix string

@description('Invoice section resource ID that pays for newly created subscriptions. Only needed when creating.')
param billingScope string = ''

@description('Existing subscription ID for the management (platform) subscription. Leave empty to create one.')
param managementSubscriptionId string = ''

@description('Display name for a new management subscription. Used when managementSubscriptionId is empty.')
param managementSubscriptionName string = ''

@description('Existing subscription ID for the workload subscription. Leave empty to create one.')
param workloadSubscriptionId string = ''

@description('Display name for a new workload subscription. Used when workloadSubscriptionId is empty.')
param workloadSubscriptionName string = ''

var createManagement = empty(managementSubscriptionId)
var createWorkload = empty(workloadSubscriptionId)

// Two parallel placements of the SAME existing subscription conflict, so in a
// single-subscription setup only the workload placement runs.
var sameSubscription = !createManagement && managementSubscriptionId == workloadSubscriptionId

module managementSub '../../modules/subscription.bicep' = if (!sameSubscription) {
  name: 'sub-management'
  params: {
    managementGroupName: '${prefix}-management'
    existingSubscriptionId: managementSubscriptionId
    displayName: managementSubscriptionName
    billingScope: createManagement ? billingScope : ''
  }
}

module workloadSub '../../modules/subscription.bicep' = {
  name: 'sub-workload'
  params: {
    managementGroupName: '${prefix}-corp'
    existingSubscriptionId: workloadSubscriptionId
    displayName: workloadSubscriptionName
    billingScope: createWorkload ? billingScope : ''
  }
}

output managementSubscriptionId string = sameSubscription
  ? managementSubscriptionId
  : managementSub!.outputs.subscriptionId
output workloadSubscriptionId string = workloadSub.outputs.subscriptionId
