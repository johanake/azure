// ---------------------------------------------------------------------------
// MODULE: Log Analytics workspace
// SCOPE:  resourceGroup  (the default, so targetScope can be omitted)
// ---------------------------------------------------------------------------
@description('Azure region.')
param location string

@description('Workspace name.')
param name string

@description('Days to keep data.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB. Ingestion stops for the rest of the day once reached. Use -1 for no cap.')
param dailyQuotaGb int = 1

@description('Resource tags.')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
  }
}

output id string = workspace.id
output name string = workspace.name
