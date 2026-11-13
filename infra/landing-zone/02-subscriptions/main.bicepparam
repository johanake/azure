using 'main.bicep'

param prefix = 'az'

// Account-specific values come from environment variables, so they never end
// up in git. Put them in infra/.env (gitignored; copy infra/.env.example) and
// load it before deploying:  set -a; source .env; set +a

// The invoice section that pays for subscriptions created here. Find it with:
//   az billing profile list --account-name <billing-account> --expand invoiceSections
param billingScope = readEnvironmentVariable('AZ_BILLING_SCOPE', '')

// Platform: no ID given, so a NEW subscription with this name is created
// under <prefix>-management.
param managementSubscriptionName = 'az-management'

// Workload: an existing subscription, moved under <prefix>-corp.
// Leave AZ_WORKLOAD_SUBSCRIPTION_ID empty and set workloadSubscriptionName to
// create a new one instead.
param workloadSubscriptionId = readEnvironmentVariable('AZ_WORKLOAD_SUBSCRIPTION_ID', '')
