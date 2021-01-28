param location string = resourceGroup().location
param frontDoorName string = 'afd${uniqueString(resourceGroup().id)}'
param allowedCountryCodes array = [
  'AU' // Australia
  'NZ' // New Zealand
  'ZZ' // Unknown - i.e. traffic that can't be associated with a location
]

module functionApp 'function.bicep' = {
  name: 'functionapp'
  params: {
    location: location
  }
}

module frontDoor 'front-door.bicep' = {
  name: 'front-door'
  params: {
    frontDoorName: frontDoorName
    backendAddress: functionApp.outputs.functionAppHostName
    functionKey: functionApp.outputs.functionAppKey
    allowedCountryCodes: allowedCountryCodes
  }
}

output functionUrl string = 'https://${frontDoor.outputs.frontDoorHostName}/api/${functionApp.outputs.functionName}'
