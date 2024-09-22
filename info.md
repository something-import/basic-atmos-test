
* Providers - A resource provider handles communications with a cloud service to create, read, update, and delete the resources
* Components - logical grouping of resources, such as Entra, ExternalIdentities
* Resources - represent the fundamental units that make up cloud infrastructure, such as conditional access policy
  * logical name - how a resource definition is known inside this module - unique across environment (tenant-level)
  * physical name - unique name used for the resource in the cloud provider (if supported, for Graph see [uniquelyNameResources](https://learn.microsoft.com/en-us/graph/templates/concept-uniquely-named-resources))
  * physical id - unique identifier (key) used for the resource in the cloud provider