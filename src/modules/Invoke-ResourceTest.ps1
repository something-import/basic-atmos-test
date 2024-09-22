
function Invoke-ResourceTest {
    [CmdletBinding()]
    param (
        $ResourcePath,
        [ValidateSet("Get", "Compare", "Export")]
        $Action
    )

    begin {
        # look at https://github.com/microsoft/MSCloudLoginAssistant
    }

    process {
        try {
            # Attempt to find and invoke a resource function dynamically
            if (!(Test-Path $ResourcePath)) {
                throw "No valid resource path found"
            }

            # Load resource definition
            $resourceDefinition = Get-Content -Raw -Path $ResourcePath | ConvertFrom-Yaml -Ordered

            $i = 1
            foreach ($resource in $resourceDefinition.resources.GetEnumerator()) {
                Write-Verbose "Processing [$i/$($resourceDefinition.resources.Count)] resource: '$($resource.Name)'"

                $componentScriptPath = Get-ChildItem -Path ($PSScriptRoot + '\..\resources\') -Recurse -Filter "$($resource.Value.resourceType).ps1" -File
                Write-Verbose "Component script path: $($componentScriptPath.FullName)"
                # $componentDirectoryFiles = Get-ChildItem -Path $componentDirectory.FullName

                # Search the AST for function definitions
                $myScript = Get-Command $componentScriptPath.FullName
                $scriptAST = $myScript.ScriptBlock.AST
                $functionDefinitions = $scriptAST.FindAll({
                        $args[0] -is [Management.Automation.Language.FunctionDefinitionAst]
                    }, $false)

                # OR
                # Get-ChildItem function:\"Get-$($resource.Value.resourceType)"
                # OR
                # $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($componentScriptPath.FullName, [ref]$null, [ref]$null)
                # $scriptAst.FindAll({$args[0] -is [Management.Automation.Language.FunctionDefinitionAst]}, $false) | Select-Object -ExpandProperty Name

                if ($null -eq $functionDefinitions) {
                    throw "Unable to find any functions for resource type."
                }

                Write-Verbose "Found functions: '$($functionDefinitions.Name -join ',')'"

                if (($functionDefinitions | Measure-Object).Count -ne 4) {
                    throw "Unable to find all functions for resource type. Ensure that the component definition is valid for '$($resource.Value.resourceType)'."
                }

                $params = ([hashtable]$resource.Value).Clone()

                # FUTURE
                # LOAD THE SCHEMA AND CONFIG AND PASS THROUGH AS PARAMETERS OR STORE IN $SCRIPT:* VARIABLE
                switch ($Action) {
                    'Export' { # for exporting a current cloud resource to file and brining it under management
                        & "Export-$($resource.Value.resourceType)" @params
                    }
                    'Get' { # get the current state and properties of managed resource
                        & "Get-$($resource.Value.resourceType)" @params
                    }
                    'Compare' { # compare current resource properties (cloud) with definition (yaml file)
                        # https://github.com/microsoft/Microsoft365DSC/blob/Dev/Modules/Microsoft365DSC/DSCResources/MSFT_AADGroup/MSFT_AADGroup.psm1#L1034
                        # Similar to Test-M365DSCParameterState function
                        # https://github.com/microsoft/Microsoft365DSC/blob/Dev/Modules/Microsoft365DSC/Modules/M365DSCUtil.psm1#L601
                        & "Compare-$($resource.Value.resourceType)" @params
                    }
                    Default {}
                }
                $i++
            }

        }
        catch {
            throw
        }
    }

    end {

    }
}