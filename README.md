# Azure Front Door with consumption HTTP function and geo-blocking

This example illustrates how to use Azure Front Door in conjunction with HTTP-triggered Azure Functions on the consumption plan, with Front Door's geo-blocking feature enabled.

## ARM template language

The ARM templates are built using [Bicep](https://github.com/Azure/bicep/), the new ARM template language.
You can use the `main.json` template as a standard ARM template if you prefer.

## Functions

This example deploys the function app with an example HTTP-triggered function.
When you deploy the template, the `functionUrl` output will contain the Front Door-based URL to access.

**Note that it can take several minutes after the template deployment completes before Front Door will successfully serve traffic.**

## Securing Front Door and function app communication

Front Door acts as a reverse proxy, and so it's important to block traffic into the function app unless it has flowed through Front Door.
For function apps deployed in the consumption plan, there is no way to easily block traffic at a network level.
Instead, this example makes use of the [access keys for HTTP triggered functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=csharp#authorization-keys).
Clients calling the API don't need to specify the function key.
Instead, Front Door attaches the function key to incoming requests using the `x-functions-key` request header by using the [Front Door rules engine](https://docs.microsoft.com/en-us/azure/frontdoor/front-door-rules-engine).
Since Front Door is the only entity that knows the key, this effectively authenticates that the traffic has come through Front Door.
The ARM template has been configured to automatically propagate the function app system key into Front Door's rules engine configuration.
The use of the system key means that all HTTP-triggered functions within the app will work with the same key.

## Geo-blocking

Front Door is configured with its Web Application Firewall (WAF) for its [geo-blocking capabilities](https://docs.microsoft.com/en-us/azure/frontdoor/front-door-geo-filtering).
The WAF is configured to only allow traffic that originates from certain countries.
By default these are Australia, New Zealand, and also any traffic that is from an unknown country (to avoid accidentally blocking traffic that is ambiguous).

## Front Door deployment
Due to the way Front Door works with ARM templates, the Front Door instance is deployed twice.
The first time, it is deployed without a rules engine.
The template then deploys the rules engine, and then re-deploys the Front Door with the rules engine attached.

## Deployment note
Sometimes the first deployment of this template will fail due to an internal race condition in the Front Door deployment.
If this happens, please simply retry the deployment.
