
<#
.SYNOPSIS
    Get an EIDGroup using the Graph provider
.EXAMPLE
    Get-EIDGroup
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>
function Get-EIDGroup {
    [CmdletBinding()]
    param (
        # id or other primary key for resource in cloud service
        [Parameter(Mandatory = $false)]
        [string]
        $PhysicalId,
        [Parameter(Mandatory = $false)]
        $Properties,
        [Parameter(Mandatory = $false)]
        $Schema,
        [Parameter(Mandatory = $false)]
        $Config
    )

    begin {
        try {
            # move all this into function and call as needed
            # allow passing in schema and config in parameters
            # allow storing schema and config in $script variable to save computation every time
            if (!$Schema -or !$Config) {
                Write-Verbose "Loading resource dependencies..."
                $resourceTypeName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

                if (!$Schema) {
                    Write-Verbose "Loading schema..."
                    $schemaPath = Join-Path -Path $PSScriptRoot -ChildPath "${resourceTypeName}.schema.yaml"
                    if (Test-Path $schemaPath) {
                        $Schema = (Get-Content -Raw -Path $schemaPath | ConvertFrom-Yaml -Ordered).schema
                    }
                }

                if (!$Config) {
                    Write-Verbose "Loading config..."
                    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "${resourceTypeName}.config.yaml"
                    if (Test-Path $configPath) {
                        $Config = (Get-Content -Raw -Path $configPath | ConvertFrom-Yaml -Ordered)
                    }
                }
            }

            # check that the current connection is valid for this resource type
        }
        catch {
            throw
        }
    }

    process {
        try {
            # Load the provider and its api definition
            $activeProvider = $Config.provider."$($Config.provider.use)"
            $apiProvider = $activeProvider.api.list

            # Default params
            $GetParameters = @{
                # Filter      = $Filter
                Headers     = @{}
                ErrorAction = 'Stop'
                OutputType  = 'PSObject'
                Method      = $apiProvider.method
                Uri         = "$($activeProvider.apiVersion)/"
            }

            # Figure out if getting just 1 resource or all of them
            if ($PSBoundParameters.ContainsKey('PhysicalId')) {
                Write-Verbose "Identifier '$PhysicalId' provided, attempt to get existing resource"
                $apiProvider = $activeProvider.api.get
                $GetParameters.Uri += "$($apiProvider.uri)"
                $GetParameters.Uri = $GetParameters.Uri -replace "{id}", $PhysicalId
            }
            else {
                # No key specified, get all resources
                $GetParameters.Uri += "$($apiProvider.uri)"
            }

            # Handle request uri query parameters (odata)
            # Move this to shared function
            if ($apiProvider.Contains('queryParams')) {
                Write-Verbose "Processing query parameters..."

                $queryParams = @()
                if ($apiProvider.queryParams.Contains('expand')) {
                    $queryParams += "`$expand=" + $apiProvider.queryParams.expand
                }

                if ($apiProvider.queryParams.Contains('filter')) {
                    Write-Verbose "Processing filter query parameter..."

                    # Define the list of attributes that require advanced queries capabilities
                    $attributesToCheck = @(
                        'description',
                        'displayName',
                        'expirationDateTime'
                        'mail',
                        'mailNickname',
                        'onPremisesSamAccountName',
                        'onPremisesSecurityIdentifier',
                        'onPremisesSyncEnabled',
                        'preferredLanguage'
                    )

                    # Initialize a flag to indicate whether any attribute matches the condition
                    $matchConditionFound = $false

                    # Check each attribute in the list
                    foreach ($attribute in $attributesToCheck) {
                        if ($apiProvider.queryParams.filter -like "*$attribute eq null*" -or $apiProvider.queryParams.filter -like "*$attribute startsWith *") {
                            $matchConditionFound = $true
                            break
                        }
                    }

                    # If any attribute matches, add required advanced query parameters to $GetParameters
                    if ($matchConditionFound -or $apiProvider.queryParams.filter -like '*endsWith*' `
                            -or $apiProvider.queryParams.filter -like '*not(*' `
                            -or $apiProvider.queryParams.filter -like '* ne *') {
                        $GetParameters.Headers.Add('ConsistencyLevel', 'eventual')
                        $queryParams += "`$count=true"
                    }

                    $queryParams += "`$filter=" + $apiProvider.queryParams.filter
                }

                if ($queryParams.count -gt 0) {
                    $GetParameters.Uri = $GetParameters.Uri + "?$($queryParams -join '&')"
                }
            }

            # Get from schema or from list of props passed in
            Write-Verbose "Uri: $($GetParameters.Uri)"
            $response = Invoke-MgGraphRequest @GetParameters # normally handle with graph request to get paged results
            $groups = $response
            if (!$PhysicalId) {
                $groups = $groups.value
            }

            # $i = 1
            # foreach ($group in $groups) {
            #     Write-Verbose "Processing [$i/$($groups.Count)] $($group.DisplayName)"
            #     # do comparison
            # }

            $groups | Select-Object -Property $Schema.selectProperties.keys
        }
        catch {
            throw
        }
    }

    end {

    }
}

function Set-EIDGroup {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

    }

    end {

    }
}

function Compare-EIDGroup {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        # Two supported comparison methods:

        # Comparison 1 - Compare passed in resource with one in cloud provider - requires using Get-EIDGroup to compare existing

        # Comparison 2 - Compare passed in resource with another definition (additional parameter) - doesn't require connection

    }

    end {

    }
}

# Export a resource to definition file
# Take an existing resource under management
function Export-EIDGroup {
    [CmdletBinding()]
    param (
        # ODATA Filter
        [Parameter(Mandatory = $false)]
        [string]
        $Filter,
        [Parameter(Mandatory = $false)]
        [string[]]
        $Select,
        [Parameter(Mandatory = $false)]
        [string[]]
        $Props,
        [Parameter(Mandatory = $false)]
        $Connection
    )

    begin {
        Write-Verbose "Loading dependencies from directory..."
        $resourceTypeName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        $schemaPath = Join-Path -Path $PSScriptRoot -ChildPath "${resourceTypeName}.schema.yaml"
        $configPath = Join-Path -Path $PSScriptRoot -ChildPath "${resourceTypeName}.config.yaml"
        if (Test-Path $schemaPath) {
            $Schema = (Get-Content -Raw -Path $schemaPath | ConvertFrom-Yaml -Ordered).schema
        }
        if (Test-Path $configPath) {
            $Config = (Get-Content -Raw -Path $configPath | ConvertFrom-Yaml -Ordered)
        }

    }

    process {
        try {
            # $Schema
            # $Config
            $ExportParameters = @{
                # Filter      = $Filter
                # All         = $true
                Headers     = @{}
                ErrorAction = 'Stop'
                OutputType  = 'PSObject'
                Method      = $Config.provider.graph.api.list.method
                Uri         = "$($Config.provider.graph.apiVersion)/$($Config.provider.graph.api.list.uri)"
            }

            if ($Filters) {
                # Define the list of attributes that require advanced queries capabilities
                $attributesToCheck = @(
                    'description',
                    'displayName',
                    'expirationDateTime'
                    'mail',
                    'mailNickname',
                    'onPremisesSamAccountName',
                    'onPremisesSecurityIdentifier',
                    'onPremisesSyncEnabled',
                    'preferredLanguage'
                )

                # Initialize a flag to indicate whether any attribute matches the condition
                $matchConditionFound = $false

                # Check each attribute in the list
                foreach ($attribute in $attributesToCheck) {
                    if ($Filter -like "*$attribute eq null*" -or $Filter -like "*$attribute startsWith *") {
                        $matchConditionFound = $true
                        break
                    }
                }

                # If any attribute matches, add required advanced query parameters to $ExportParameters
                if ($matchConditionFound -or $Filter -like '*endsWith*') {
                    $ExportParameters.Headers.Add('CountVariable', 'count')
                    $ExportParameters.Headers.Add('ConsistencyLevel', 'eventual')
                }
            }

            # Get from schema or from list of props passed in
            Write-Verbose "Uri: $($ExportParameters.Uri)"
            $response = Invoke-MgGraphRequest @ExportParameters # normally handle with graph request to get paged results
            $exportedGroups = $response.value
            # $i = 1
            # foreach ($group in $exportedGroups) {
            #     Write-Verbose "Processing [$i/$($exportedGroups.Count)] $($group.DisplayName)"
            #     # do comparison
            # }

            $exportedGroups | Select-Object -Property $Schema.selectProperties.keys

        }
        catch {
            throw
        }
    }

    end {

    }
}