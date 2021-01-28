param frontDoorName string
param backendAddress string
param functionKey string
param allowedCountryCodes array
param blockResponseCode int = 403

var rulesEngineName = 'AddFunctionKey'
var wafPolicyName = 'MyWafPolicy'

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-04-01' = {
  name: wafPolicyName
  location: 'global'
  properties: {
    policySettings: {
      mode: 'Prevention'
      customBlockResponseStatusCode: blockResponseCode
    }
    customRules: {
      rules: [
        {
          name: 'GeoBlock'
          priority: 10
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'GeoMatch'
              negateCondition: true
              matchValue: allowedCountryCodes
            }
          ]
        }
      ]
    }
  }
}

// Due to the ARM resource model for Front Door, we have to deploy the Front Door instance twice - once without the rules engine and then again with it included.

module frontDoorDeployment1 'front-door-internal.bicep' = {
  name: 'front-door-deployment-1'
  params: {
    frontDoorName: frontDoorName
    backendAddress: backendAddress
    wafPolicyId: wafPolicy.id
    rulesEngineId: ''
  }
}

resource rulesEngine 'Microsoft.Network/frontDoors/rulesEngines@2020-05-01' = {
  name: '${frontDoorName}/${rulesEngineName}'
  dependsOn: [
    frontDoorDeployment1
  ]
  properties: {
    rules: [
      {
        name: 'AddFunctionKey'
        priority: 1
        matchConditions: []
        action: {
          requestHeaderActions:[
            {
              headerActionType: 'Append'
              headerName: 'x-functions-key'
              value: functionKey
            }
          ]
        }
      }
    ]
  }
}

module frontDoorDeployment2 'front-door-internal.bicep' = {
  name: 'front-door-deployment-2'
  dependsOn: [
    rulesEngine
  ]
  params: {
    frontDoorName: frontDoorName
    backendAddress: backendAddress
    wafPolicyId: wafPolicy.id
    rulesEngineId: rulesEngine.id
  }
}

output frontDoorHostName string = reference(resourceId('Microsoft.Network/frontDoors', frontDoorName), '2020-05-01').frontendEndpoints[0].properties.hostName
