targetScope = 'subscription'

@description('Required. The name of the Resource Group')
param resourceGroupName string

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location

@description('Optional. Tags of the storage account resource.')
param tags object = {}

@description('Do not populate. It will contain a timestamp based on UTC.')
param timeStamp string = utcNow()

resource resourceGroup 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  location: location
  name: resourceGroupName
  tags: tags
  properties: {}
}

@description('Module for deploying a Function App.')
module functionApp 'modules/function-app.bicep' = {
  name: 'deploy-function-app-${timeStamp}'
  scope: resourceGroup
  params: {}
}

@description('Module for deploying a function app.')
module logicApp './modules/logic-app.bicep' = {
  name: 'deploy-logic-app-${timeStamp}'
  scope: resourceGroup
  params: {}
}

@description('Module for deploying an Azure Key Vault instance.')
module keyVault './modules/key-vault.bicep' = {
  name: 'deploy-key-vault-${timeStamp}'
  scope: resourceGroup
  params: {}
}

output resourceGroupName string = resourceGroup.name
output resourceGroupResourceId string = resourceGroup.id
