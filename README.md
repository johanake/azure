# az — Azure infrastructure (Bicep) and application source

A minimal, learning-sized Azure landing zone in Bicep, modelled on the
[Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/).

## Layout

```
infra/
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

**Folders map to the Azure hierarchy:**

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

- **Landing zone (platform):** the foundation. It covers the management groups,
  policy, shared logging and networking. You build it once.
- **Workload zone (application landing zone):** a subscription that sits under
  `az-landingzones`, where an app team deploys its resources. It inherits
  guardrails from the management groups above it.
- **modules/:** contain no environment-specific values. The entry-point
  `main.bicep` files compose the modules, and the `.bicepparam` files supply
  the values.

## Secret scanning

A [gitleaks](https://github.com/gitleaks/gitleaks) pre-commit hook blocks
commits that contain secrets. `.gitleaks.toml` adds rules for Azure
subscription IDs and billing scopes, which belong in the gitignored
`infra/.env`. Set it up once after cloning:

```bash
pip install pre-commit      # or: brew install pre-commit
pre-commit install
```

## Deploying (in order)

```bash
cd infra
LOC=swedencentral

# 0. Account-specific values (subscription ID, billing scope) live in a local,
#    gitignored .env file. Create it once from the template, then load it:
cp -n .env.example .env   # then edit .env
set -a; source .env; set +a

# 1. Management groups (needs Owner at the Tenant Root Group, see below).
#    The Tenant Root Group's ID is the tenant ID:
#    az account show --query tenantId -o tsv
az deployment mg create --management-group-id <tenant-id> --location $LOC \
  --parameters landing-zone/01-management-groups/main.bicepparam

# 2. Subscriptions → management groups: creates new ones or moves existing
#    ones (see "Subscriptions" below). The outputs give both subscription IDs.
az deployment mg create --management-group-id az --location $LOC \
  --parameters landing-zone/02-subscriptions/main.bicepparam

# 3. Shared platform services for workloads in the workload-zone
az account set --subscription <management-subscription-id>
az deployment sub create --location $LOC \
  --parameters landing-zone/03-management/main.bicepparam

# 4. A workload
az account set --subscription <workload-subscription-id>
az deployment sub create --location $LOC \
  --parameters workload-zones/sample-app/dev.bicepparam
```

Replace `create` with `what-if` (for example `az deployment sub what-if ...`) to
preview changes without applying them.

### Access needed for steps 1 and 2

Being subscription Owner is not enough; these steps write at tenant level.

1. In the portal: Microsoft Entra ID → Properties → set **Access management
   for Azure resources** to **Yes**.
2. Give yourself Owner at the root, then log out and in again:

   ```bash
   az role assignment create \
     --assignee-object-id $(az ad signed-in-user show --query id -o tsv) \
     --assignee-principal-type User --role Owner --scope /
   ```

3. Set the portal toggle back to **No** afterwards. The role assignment stays.

### Subscriptions (step 2)

`02-subscriptions/main.bicepparam` decides, for each of the two subscriptions,
whether to move an existing one or create a new one:

| Parameter | Effect |
|---|---|
| `managementSubscriptionId` / `workloadSubscriptionId` | Moves that existing subscription into its management group. |
| `managementSubscriptionName` / `workloadSubscriptionName` | Creates a new subscription with that name (when the matching ID is left out). |
| `billingScope` | The invoice section that pays for created subscriptions. Only needed when creating. |

The account-specific values are not in git. The param file reads them from
environment variables, which you set in `infra/.env` (gitignored; copy
`infra/.env.example`):

| Variable | Parameter |
|---|---|
| `AZ_BILLING_SCOPE` | `billingScope` |
| `AZ_WORKLOAD_SUBSCRIPTION_ID` | `workloadSubscriptionId` |

With both set, it creates a new `az-management` subscription under
`az-management` and moves the existing subscription under `az-corp`. If you
forget to load `.env`, both values are empty, and the deployment tries to
create the workload subscription too, so run `what-if` first.

- **Creating** needs a Microsoft Customer Agreement or Enterprise Agreement
  billing account. Find the invoice section ID with
  `az billing profile list --account-name <billing-account> --expand invoiceSections`.
- **Single subscription:** set both IDs to the same value. Only the workload
  placement runs, so it ends up under `az-corp`, `az-management` stays empty,
  and steps 3 and 4 both deploy into that one subscription.
- **Removing** a subscription is not possible from Bicep. Cancel it in the
  portal; Azure deletes it about 90 days later.

## Bicep concepts shown

| Concept | Where |
|---|---|
| `targetScope` (tenant / managementGroup / subscription / resourceGroup) | the top of every file |
| Deploying a tenant-level resource from an MG deployment (`scope: tenant()`) | `modules/management-group.bicep` |
| Implicit dependencies through module outputs | `01-management-groups/main.bicep` |
| `existing` resources and conditional (`if`) resources | `modules/subscription.bicep`, `02-subscriptions/main.bicep` |
| Cross-scope modules (`scope: resourceGroup(...)`) and explicit `dependsOn` | `03-management`, `sample-app` |
| Parameter decorators (`@allowed`, `@minLength`, `@description`) | `sample-app/main.bicep` |
| `.bicepparam` files per environment | next to each `main.bicep` |
