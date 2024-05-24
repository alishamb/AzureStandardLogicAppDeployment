param location string = resourceGroup().location
param tags object = {}

param logicAppName string

param serverFarm object
param pdns object
param vnet object

param logicAppPrivateEndpoint string
param appServicePlanName string

param keyvaultConnectionName string
param keyVaultConnectionRuntimeUrl string
param storageAccountName string
@secure()
param storageAccountKey string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: serverFarm.sku
  kind: 'elastic'
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 20
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: serverFarm.zoneRedundant
  }
}

resource logicApp_resource 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WORKFLOWS_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'WORKFLOWS_LOCATION'
          value: location
        }
        {
          name: 'WORKFLOWS_RESOURCE_GROUP_NAME'
          value: resourceGroup().name
        }
        {
          name: 'KEYVAULT_CONNECTION_RUNTIMEURL'
          value: keyVaultConnectionRuntimeUrl
        }
        {
          name: 'WEBSITE_WEBDEPLOY_USE_SCM'
          value: 'true'
        }
        {
          name: 'PDNS_SUBSCRIPTION_ID'
          value: pdns.subscriptionId
        }
        {
          name: 'PDNS_RESOURCE_GROUP_NAME'
          value: pdns.resourceGroupName
        }
        {
          name: 'KEY_VAULT_CONNECTION_NAME'
          value: keyvaultConnectionName
        }
      ]
    }
    hostNameSslStates: [
      {
        name: '${logicAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${logicAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlan.id
    reserved: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    //scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    publicNetworkAccess: 'Disabled'
    storageAccountRequired: false
  }
}

resource logicApp_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: logicApp_resource
  name: 'ftp'
  location: location
  properties: {
    allow: false
  }
}

resource logicApp_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: logicApp_resource
  name: 'scm'
  location: location
  properties: {
    allow: false
  }
}

resource logicApp_web 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: logicApp_resource
  name: 'web'
  location: location
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v6.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$${logicAppName}'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 2
    publicNetworkAccess: 'Disabled'
    cors: {
      allowedOrigins: []
      supportCredentials: false
    }
    localMySqlEnabled: false
    managedServiceIdentityId: 47503
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Deny'
        priority: 2147483647
        name: 'Deny all'
        description: 'Deny all access'
      }
    ]
    ipSecurityRestrictionsDefaultAction: 'Deny'
    scmIpSecurityRestrictionsUseMain: true
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 1
    functionAppScaleLimit: 0
    minimumElasticInstanceCount: 1
    azureStorageAccounts: {}
  }
}

resource logicApp_logicApp_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: logicApp_resource
  name: '${logicAppName}.azurewebsites.net'
  location: location
  properties: {
    siteName: logicAppName
    hostNameType: 'Verified'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: logicAppPrivateEndpoint
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '/subscriptions/${vnet.subscriptionId}/resourceGroups/${vnet.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnet.name}/subnets/${vnet.subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${logicAppPrivateEndpoint}-connection'
        properties: {
          privateLinkServiceId: logicApp_resource.id
          groupIds: ['sites']
        }
      }
    ] 
  }
}

resource privateEndpointPDNSConnection 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: 'logic-app-pe/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink_azurewebsites_net'
        properties: {
          privateDnsZoneId: '/subscriptions/${pdns.subscriptionId}/resourceGroups/${pdns.resourceGroupName}/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

output logicAppIdentity string = logicApp_resource.identity.principalId


