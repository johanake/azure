# Landing zone governance: management groups, subscriptions and policy

A minimal Azure landing zone in Bicep, modelled on the
[Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/).
It builds the governance skeleton that every workload sits in: a management
group hierarchy, subscriptions placed in it, a central Log Analytics
workspace, and a sample workload that uses it.

_Blog post coming soon._

## Architecture

```
Tenant Root Group                                     <- 01-management-groups
└── az
    ├── az-platform
    │   └── az-management   ── [management sub]       <- 02-subscriptions
    │                            └── rg-az-management-*       <- 03-management
    │                                 └── log-az-management-*
    └── az-landingzones
        └── az-corp         ── [workload sub]         <- 02-subscriptions
                                 └── rg-sample-dev-*          <- workload-zones/sample-app
                                      └── stsampledev...
```

- **Management group:** a folder for subscriptions. Policy and access (RBAC)
  assigned to a management group are inherited by everything beneath it. `az`
  is the intermediate root where org-wide policy belongs. Putting it under
  Tenant Root Group, rather than assigning at the Tenant Root Group itself,
  keeps the tenant root clean.
- **Platform landing zone** (`az-platform`): the subscriptions for shared
  services that the platform team builds once, such as logging, and later
  networking and identity.
- **Application landing zones** (`az-landingzones`): the subscriptions where
  app teams deploy workloads. They inherit the guardrails from above. `az-corp`
  is for internal, corporate-network-connected workloads.
- **Workload zone:** what one app team owns inside its subscription.
  `sample-app` shows the pattern: a resource group and a storage account.

## When to use it

- **Use it when** you're learning how Azure governance fits together, setting
  up a personal or small-company tenant, or you want a small, readable starting
  point you fully understand before adding policy and networking.
- **Don't use it when** you need an enterprise-ready landing zone with
  policy-driven guardrails, hub-and-spoke networking and identity built in.
  Start from the [Azure Landing Zones accelerator](https://aka.ms/alz) or the
  [Azure Verified Modules](https://aka.ms/avm) pattern modules instead.

## What gets deployed

| Resource | Scope | Why |
|---|---|---|
| Management groups `az`, `az-platform`, `az-management`, `az-landingzones`, `az-corp` | Tenant | The hierarchy that policy and RBAC are assigned to. |
| Subscription placement (moves an existing subscription) | Management group | Puts the workload subscription under `az-corp`. |
| Subscription alias (creates a new subscription) | Tenant | Creates the `az-management` subscription under `az-management`. Only when no ID is given. |
| Resource group `rg-az-management-<region>` | Management subscription | Holds the shared platform services. |
| Log Analytics workspace `log-az-management-<region>` | Resource group | Central place for every workload's logs. Capped at 1 GB/day, kept for 30 days. |
| Resource group `rg-sample-dev-<region>` | Workload subscription | The sample workload's resources. |
| Storage account `stsampledev<hash>` | Resource group | Sample resource: TLS 1.2, HTTPS only, no public blob access. |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with
  Bicep CLI 0.30 or later (`az bicep upgrade`).
- **Owner at the Tenant Root Group** for steps 1 and 2, because they write at
  tenant level. Owning a subscription isn't enough. To get it:
  1. In the portal, go to Microsoft Entra ID → Properties and set **Access
     management for Azure resources** to **Yes**.
  2. Give yourself Owner at the root, then sign out and in again:

     ```bash
     az role assignment create \
       --assignee-object-id $(az ad signed-in-user show --query id -o tsv) \
       --assignee-principal-type User --role Owner --scope /
     ```

  3. Set the portal toggle back to **No**. The role assignment stays.
- **At least one existing subscription** to use as the workload subscription.
- **To create a new subscription** (the default for `az-management`): a
  Microsoft Customer Agreement or Enterprise Agreement billing account, and
  permission to create subscriptions on its invoice section. On a
  pay-as-you-go or Visual Studio subscription, use a single subscription
  instead (see [Adapting it](#adapting-it)).
- **Contributor** (or Owner) on the management and workload subscriptions for
  steps 3 and 4.

## Deploy

Run every command from this folder, in order. Each step depends on the one
before it.

```bash
cd reference-architectures/landing-zone-governance
LOC=swedencentral
```

0. **Load your account-specific values.** The subscription ID and billing
   scope identify your account, so they live in a gitignored `.env` file
   instead of the param files:

   ```bash
   cp -n .env.example .env   # then edit .env
   set -a; source .env; set +a
   ```

1. **Create the management group hierarchy** (Owner at Tenant Root Group).
   It deploys at the Tenant Root Group, whose ID is your tenant ID:

   ```bash
   az deployment mg create \
     --management-group-id $(az account show --query tenantId -o tsv) \
     --location $LOC \
     --parameters landing-zone/01-management-groups/main.bicepparam
   ```

2. **Place the subscriptions** (Owner at Tenant Root Group, plus billing
   permission when creating). This moves the existing workload subscription
   under `az-corp` and creates `az-management`. The deployment outputs give
   both subscription IDs, which you need next:

   ```bash
   az deployment mg create --management-group-id az --location $LOC \
     --parameters landing-zone/02-subscriptions/main.bicepparam
   ```

3. **Deploy the shared platform services** (Contributor on the management
   subscription). This creates the central Log Analytics workspace:

   ```bash
   az account set --subscription <management-subscription-id>
   az deployment sub create --location $LOC \
     --parameters landing-zone/03-management/main.bicepparam
   ```

4. **Deploy a workload** (Contributor on the workload subscription). This is
   the step an app team repeats for each workload:

   ```bash
   az account set --subscription <workload-subscription-id>
   az deployment sub create --location $LOC \
     --parameters workload-zones/sample-app/dev.bicepparam
   ```

To preview any step without changing anything, replace `create` with
`what-if`, for example `az deployment mg what-if ...`. Always preview step 2:
if `.env` isn't loaded, both values are empty, and it tries to create a new
workload subscription instead of moving yours.

## Configuration

| Parameter / variable | File | Default | Effect |
|---|---|---|---|
| `prefix` | `01-…`, `02-…`, `03-…/main.bicepparam` | `az` | Management group IDs and platform resource names. Must be the same in all three files. |
| `rootParentId` | `01-management-groups/main.bicep` | tenant ID | Parent of the hierarchy. Change it to nest the hierarchy under another management group. |
| `AZ_WORKLOAD_SUBSCRIPTION_ID` → `workloadSubscriptionId` | `.env` | empty | Existing subscription to move under `az-corp`. If empty, a new one is created from `workloadSubscriptionName`. |
| `workloadSubscriptionName` | `02-subscriptions/main.bicepparam` | not set | Name for a new workload subscription. Used only when no workload ID is given. |
| `managementSubscriptionId` | `02-subscriptions/main.bicepparam` | not set | Existing subscription to move under `az-management`. If set, no subscription is created. |
| `managementSubscriptionName` | `02-subscriptions/main.bicepparam` | `az-management` | Name for the new management subscription. |
| `AZ_BILLING_SCOPE` → `billingScope` | `.env` | empty | Invoice section that pays for new subscriptions. Find it with `az billing profile list --account-name <billing-account> --expand invoiceSections`. |
| `location` | `03-management`, `sample-app` | the `--location` you deploy with | Region for resource groups and resources. |
| `tags` | `03-management`, `sample-app` param files | `owner` tag | Merged with the `managedBy`, `zone`, `environment` and `workload` tags that are always added. |
| `environment` | `sample-app/dev.bicepparam` | `dev` | `dev`, `test` or `prod`. Used in resource names. |
| `workloadName` | `sample-app/dev.bicepparam` | `sample` | 2–10 characters. Used in resource names. |

The workspace's retention (30 days) and daily cap (1 GB) are parameters of
`modules/log-analytics.bicep`. Pass them from `03-management/main.bicep` to
change them.

## Adapting it

- **Use your own prefix:** change `prefix` in all three landing-zone param
  files, and pass the new value to `--management-group-id` in step 2.
- **Single subscription** (pay-as-you-go, Visual Studio, free trial): set
  `managementSubscriptionId` in `02-subscriptions/main.bicepparam` to the same
  ID as your workload subscription. Only the workload placement runs, so the
  subscription ends up under `az-corp`, `az-management` stays empty, and steps
  3 and 4 both deploy into that one subscription.
- **Add a workload:** copy `workload-zones/sample-app` to
  `workload-zones/<name>`, then edit `main.bicep` and its param file. For more
  environments, add a param file each (`test.bicepparam`, `prod.bicepparam`).
- **Add management groups:** add a module call to
  `01-management-groups/main.bicep`. The common next ones are `online` (for
  internet-facing workloads), `sandbox` and `decommissioned`.
- **Add policy:** assign policies or initiatives at the `az` management group
  for org-wide rules (allowed regions, required tags), or lower down for
  narrower ones. Start in audit mode before you deny.
- **Send workload logs centrally:** add diagnostic settings to workload
  resources that point at the workspace ID output by step 3.
- **Toward production:** add policy, hub-and-spoke networking, a connectivity
  subscription under `az-platform`, and run the deployments from a pipeline
  with a workload identity instead of your own user.

## Cost

- **Free:** management groups, subscription placement, resource groups, role
  assignments, and the subscriptions themselves.
- **Billed:** Log Analytics, per GB ingested, and the storage account, for
  data stored and transactions. Empty, the storage account costs close to
  nothing.
- **Limits in place:** the workspace stops ingesting for the day after 1 GB,
  and its 30-day retention stays within the included retention period, so
  there's no extra retention charge.

## Clean up

Remove everything in reverse order: resources first, then subscriptions out of
the hierarchy, then management groups from the bottom up. A management group
must be empty before you can delete it.

```bash
# Workload and platform resources
az group delete --yes --subscription <workload-subscription-id> \
  --name rg-sample-dev-$LOC
az group delete --yes --subscription <management-subscription-id> \
  --name rg-az-management-$LOC

# Move subscriptions back under the Tenant Root Group
TENANT=$(az account show --query tenantId -o tsv)
az account management-group subscription add --name $TENANT \
  --subscription <workload-subscription-id>
az account management-group subscription add --name $TENANT \
  --subscription <management-subscription-id>

# Management groups, children first
for mg in az-corp az-landingzones az-management az-platform az; do
  az account management-group delete --name $mg
done
```

- **A created subscription can't be removed from code.** Cancel
  `az-management` in the portal (Subscriptions → Cancel subscription), and
  Azure deletes it about 90 days later.
- **Log Analytics workspaces are soft-deleted for 14 days.** Redeploying with
  the same name in that time recovers the old workspace instead of creating a
  new one.
- Remove the Owner role at `/` if you only added it for this.

## Layout

```
landing-zone-governance/
├── .env.example                  template for local, account-specific values
├── bicepconfig.json              linter rules
├── modules/                      reusable building blocks, one per resource type
│   ├── management-group.bicep    scope: managementGroup
│   ├── subscription.bicep        scope: managementGroup
│   ├── resource-group.bicep      scope: subscription
│   ├── log-analytics.bicep       scope: resourceGroup
│   └── storage.bicep             scope: resourceGroup
├── landing-zone/                 PLATFORM: built once by the platform team
│   ├── 01-management-groups/     the management group hierarchy
│   ├── 02-subscriptions/         puts subscriptions into management groups
│   └── 03-management/            shared services (central Log Analytics)
└── workload-zones/               APPLICATIONS: one folder per workload
    └── sample-app/               resource group + storage account
```

The modules contain no environment-specific values. Each `main.bicep` composes
modules, and the `.bicepparam` file next to it supplies the values.

## Bicep concepts shown

| Concept | Where |
|---|---|
| `targetScope` (tenant / managementGroup / subscription / resourceGroup) | the top of every file |
| Deploying a tenant-level resource from an MG deployment (`scope: tenant()`) | `modules/management-group.bicep` |
| Implicit dependencies through module outputs | `01-management-groups/main.bicep` |
| `existing` resources and conditional (`if`) resources | `modules/subscription.bicep`, `02-subscriptions/main.bicep` |
| Cross-scope modules (`scope: resourceGroup(...)`) and explicit `dependsOn` | `03-management`, `sample-app` |
| Parameter decorators (`@allowed`, `@minLength`, `@description`) | `sample-app/main.bicep` |
| Reading environment variables in `.bicepparam` (`readEnvironmentVariable`) | `02-subscriptions/main.bicepparam` |
| `.bicepparam` files per environment | next to each `main.bicep` |
