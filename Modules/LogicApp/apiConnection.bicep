param keyvaultConnectionName string

@description('Location for all resources.')
param location string = resourceGroup().location
param tags object = {}

// @secure()
// param spnClientID string
// @secure()
// param spnSecret string

param keyVaultName string

resource keyVaultConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: keyvaultConnectionName
  location:location
  tags: tags
  kind: 'V2'
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'keyvault')
      type: 'Microsoft.Web/locations/managedApis'
    }
    displayName: keyvaultConnectionName
    parametervalueType: 'Alternative'
    alternativeParameterValues: {
      vaultName: keyVaultName
    }
    // parameterValues: {
    //   'token:clientId': spnClientID
    //   'token:clientSecret': spnSecret
    //   'token:TenantId': subscription().tenantId
    //   'token:grantType': 'client_credentials'
    //   'vaultName': keyVaultName
    // }
  }
}

output keyvaultendpointurl string =  reference(keyVaultConnection.id, '2016-06-01', 'full').properties.connectionRuntimeUrl
