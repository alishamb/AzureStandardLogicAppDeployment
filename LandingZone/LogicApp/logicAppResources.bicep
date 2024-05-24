param location string = resourceGroup().location
param tags object = {}

param keyVault object = {}
param keyvaultConnectionName string

param serverFarm object
param pdns object
param vnet object

param logicAppName string

param storageAccount object

param logicAppPrivateEndpoint string
param appServicePlanName  string

// param clientIDName string
// param clientSecretName string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccount.name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

module apiConnection '../../Modules/LogicApp/apiConnection.bicep' = {
  name: 'key-vault-api-connection'
  params: {
    location: location
    tags: tags
    keyVaultName: keyVault.name // Keyvault where the SPNs needed by the workflow are stored
    keyvaultConnectionName: keyvaultConnectionName
    // spnClientID: existingKeyvault.getSecret(clientIDName)
    // spnSecret: existingKeyvault.getSecret(clientSecretName)
  }
}

module standardLogicApp '../../Modules/LogicApp/StandardLogicApp.bicep' = {
  name: 'standard-logic-app'
  params: {
    location: location
    logicAppName: logicAppName
    serverFarm: serverFarm
    pdns: pdns //Subscription and RG of PDNS for sites
    keyvaultConnectionName: keyvaultConnectionName
    keyVaultConnectionRuntimeUrl: apiConnection.outputs.keyvaultendpointurl // Keyvault where the SPNs needed by the workflow are stored
    storageAccountKey: storage.listKeys().keys[0].value
    storageAccountName: storage.name
    vnet: vnet
    logicAppPrivateEndpoint: logicAppPrivateEndpoint
    appServicePlanName: appServicePlanName
  }
  dependsOn: [
    apiConnection
  ]
}

module apiConnectionAccessPolicy '../../Modules/LogicApp/accessPolicy.bicep' = {
  name: 'keyvault-connection-access-policy'
  params: {
    logicAppName: logicAppName
    keyvaultConnectionName: keyvaultConnectionName
    logicAppIdentity: standardLogicApp.outputs.logicAppIdentity
    location: location
    keyVaultName: keyVault.name
  }
  dependsOn: [
    standardLogicApp
  ]
}
