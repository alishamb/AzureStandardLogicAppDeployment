param keyvaultConnectionName string

@description('The name of the logic app to create.')
param logicAppName string

@description('Location for all resources.')
param location string = resourceGroup().location

param logicAppIdentity string
param keyVaultName string

//var roleDefinition = '4633458b-17de-408a-b874-0445c86b69e6' //Key Vault Secret User

resource keyVaultConnection 'Microsoft.Web/connections@2016-06-01' existing = {
  scope: resourceGroup()
  name: keyvaultConnectionName
}

resource keyvaultConnectorAccessPolicy 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: logicAppName
  parent: keyVaultConnection
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: subscription().tenantId
        objectId: logicAppIdentity
      }
    }
  }
}

// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(logicAppIdentity, roleDefinition )
//   properties: {
//     principalId: logicAppIdentity
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinition)
    
//   }
// }

resource keyvault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing =  {
  name: keyVaultName
}

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyvault
  properties: {
    accessPolicies: [
      {
        objectId: logicAppIdentity
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'Get'
          ]
        }  
      }
    ]
  }
}
