@description('Optional. Name of the Key Vault. If no name is provided, then unique name will be created.')
@maxLength(24)
param name string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Array of access policies object')
param accessPolicies array = []

@description('Optional. Specifies if the vault is enabled for deployment by script or compute')
@allowed([
  true
  false
])
param enableVaultForDeployment bool = true

@description('Optional. Specifies if the vault is enabled for a template deployment')
@allowed([
  true
  false
])
param enableVaultForTemplateDeployment bool = true

@description('Optional. Specifies if the azure platform has access to the vault for enabling disk encryption scenarios.')
@allowed([
  true
  false
])
param enableVaultForDiskEncryption bool = true

@description('Optional. Switch to enable/disable Key Vault\'s soft delete feature.')
param enableSoftDelete bool = true

@description('Optional. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 90

@description('Optional. Property that controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored (warning: this is a preview feature). When false, the key vault will use the access policies specified in vault properties, and any policy stored on Azure Resource Manager will be ignored. If null or not specified, the vault is created with the default value of false. Note that management actions are always authorized with RBAC.')
param enableRbacAuthorization bool = false

@description('Optional. The vault\'s create mode to indicate whether the vault need to be recovered or not. - recover or default.')
param createMode string = 'default'

@description('Optional. Provide \'true\' to enable Key Vault\'s purge protection feature.')
param enablePurgeProtection bool = false

@description('Optional. Specifies the SKU for the vault')
@allowed([
  'premium'
  'standard'
])
param vaultSku string = 'premium'

@description('Optional. Service endpoint object information')
param networkAcls object = {}

@description('Optional. Virtual Network resource identifier, if networkAcls is passed, this value must be passed as well')
param vNetId string = ''

@description('Optional. The name of the Diagnostic setting.')
param diagnosticSettingName string = 'service'

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource identifier of the Diagnostic Storage Account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource identifier of Log Analytics.')
param workspaceId string = ''

@description('Optional. Resource tags.')
param tags object = {}

@description('Generated. Do not provide a value! This date value is used to generate a SAS token to access the modules.')
param baseTime string = utcNow('u')

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'AuditEvent'
])
param logsToEnable array = [
  'AuditEvent'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var maxNameLength = 24
var uniquenameUntrim = uniqueString('Key Vault${baseTime}')
var uniquename = (length(uniquenameUntrim) > maxNameLength ? substring(uniquenameUntrim, 0, maxNameLength) : uniquenameUntrim)
var name_var = empty(name) ? uniquename : name
var virtualNetworkRules = [for networkrule in ((contains(networkAcls, 'virtualNetworkRules')) ? networkAcls.virtualNetworkRules : []): {
  id: '${vNetId}/subnets/${networkrule.subnet}'
}]
var networkAcls_var = {
  bypass: (empty(networkAcls) ? json('null') : networkAcls.bypass)
  defaultAction: (empty(networkAcls) ? json('null') : networkAcls.defaultAction)
  virtualNetworkRules: (empty(networkAcls) ? json('null') : virtualNetworkRules)
  ipRules: (empty(networkAcls) ? json('null') : ((length(networkAcls.ipRules) == 0) ? [] : networkAcls.ipRules))
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name_var
  location: location
  tags: tags
  properties: {
    enabledForDeployment: enableVaultForDeployment
    enabledForTemplateDeployment: enableVaultForTemplateDeployment
    enabledForDiskEncryption: enableVaultForDiskEncryption
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    createMode: createMode
    enablePurgeProtection: ((!enablePurgeProtection) ? json('null') : enablePurgeProtection)
    tenantId: subscription().tenantId
    accessPolicies: accessPolicies
    sku: {
      name: vaultSku
      family: 'A'
    }
    networkAcls: (empty(networkAcls) ? json('null') : networkAcls_var)
  }
}

resource keyVault_diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(workspaceId))) {
  name: '${name_var}-${diagnosticSettingName}'
  properties: {
    storageAccountId: (empty(diagnosticStorageAccountId) ? json('null') : diagnosticStorageAccountId)
    workspaceId: (empty(workspaceId) ? json('null') : workspaceId)
    metrics: ((empty(diagnosticStorageAccountId) && empty(workspaceId)) ? json('null') : diagnosticsMetrics)
    logs: ((empty(diagnosticStorageAccountId) && empty(workspaceId)) ? json('null') : diagnosticsLogs)
  }
  scope: keyVault
}

@description('The Resource Id of the Key Vault.')
output keyVaultResourceId string = keyVault.id

@description('The name of the Resource Group the Key Vault was created in.')
output keyVaultResourceGroup string = resourceGroup().name

@description('The Name of the Key Vault.')
output keyVaultName string = keyVault.name

@description('The URL of the Key Vault.')
output keyVaultUrl string = reference(keyVault.id, '2016-10-01').vaultUri
