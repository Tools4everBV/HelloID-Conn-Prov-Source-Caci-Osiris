########################################################################
# HelloID-Conn-Prov-Source-Caci-Osiris-Persons
#
# Version: 1.0.0
########################################################################
$VerbosePreference = "Continue"

#region functions
function Get-CaciOsirisEmployeeData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ApiKey,

        [Parameter(Mandatory)]
        [string]
        $BaseUrl,

        [Parameter(Mandatory)]
        [string]
        $Limit
    )

    try {
        Write-Verbose 'Adding token to authorization headers'
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Api-Key", $ApiKey)

        $splatParams = @{
            Uri     = "$BaseUrl/basis/studenten?limit=$Limit"
            Headers = $headers
        }

        Write-Verbose 'Retrieving student data'
        $responseStudents = Invoke-CaciOsirisRestMethod @splatParams

        Write-Verbose 'Retrieving education data'
        $splatParams['Uri'] = "$BaseUrl/generiek/student/opleiding"
        $responseEducation = Invoke-CaciOsirisRestMethod @splatParams

        Write-Verbose 'Combining student and education data'
        $lookupEducations = $responseEducation.Items | Group-Object -Property studentnummer -AsHashTable
        $responseStudents.items.foreach({
            $educationsInScope = $lookupEducations[$_.studentnummer]
            $educationsInScope.ForEach({
                $_ | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $_.SoplId
            })
            $_ | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $_.studentnummer
            $_ | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value $educationsInScope
        })

        Write-Verbose 'Importing raw data in HelloID'
        if (-not ($dryRun -eq $true)){
            Write-Output $responseStudents | ConvertTo-Json -Depth 10
        }
    } catch {
        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorMessage = Resolve-HTTPError -ErrorObject $ex
            Write-Verbose "Could not retrieve Caci-Osiris employees. Error: $errorMessage"
        } else {
            Write-Verbose "Could not retrieve Caci-Osiris employees. Error: $($ex.Exception.Message)"
        }
    }
}

function Invoke-CaciOsirisRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]
        $Headers
    )

    process {
        try {
            Write-Verbose "Invoking command '$($MyInvocation.MyCommand)' to endpoint '$Uri'"
            $splatRestMethodParameters = @{
                Uri         = $Uri
                Method      = 'GET'
                ContentType = 'application/json'
                Headers     =  $Headers
            }
            Invoke-RestMethod @splatRestMethodParameters
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
#endregion

#region helpers
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
            ScriptStackTrace      = $ErrorObject.ScriptStackTrace
            ErrorMessage          = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorMessage = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $httpErrorObj.ErrorMessage = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        }
        Write-Output $httpErrorObj
    }
}
#endregion

$config = $Configuration | ConvertFrom-Json
$splatParams = @{
    ApiKey  = $($config.ApiKey)
    BaseUrl = $($config.BaseUrl)
    Limit   = $($config.Limit)
}
Get-CaciOsirisEmployeeData @splatParams
