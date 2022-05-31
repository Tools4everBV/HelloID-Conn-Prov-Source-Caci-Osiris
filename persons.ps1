########################################################################
# HelloID-Conn-Prov-Source-Caci-Osiris-Persons
#
# Version: 1.0.0
########################################################################
$config = $Configuration | ConvertFrom-Json

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

#region functions
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

try {
    $headers = [System.Collections.Generic.Dictionary[string, string]]::new()
    $headers.Add("Api-Key", $($config.ApiKey))

    $splatParams = @{
        Uri     = "$($config.BaseUrl)/generiek/student/zoek/?p_std_selectie=%7B%22selectie%22%3A%22$($config.SchoolName)%22%7D&limit=$($config.Limit)"
        Headers = $headers
        Method  = 'GET'
    }

    Write-Verbose 'Retrieving student data'
    $responseStudents = Invoke-RestMethod @splatParams -Verbose:$false
    Write-Verbose " [$($responseStudents.count)] Students found"

    Write-Verbose " Adding Contracts/Educations to Students"  
    foreach ($item in $responseStudents.items) {
        $splatGetRichStudentParams = @{
            Uri     = "$($config.BaseUrl)/basis/student?p_studentnummer=$($item.studentnummer)"
            Headers = $headers
            Method  = 'GET'
        }
        $richStudentObj = Invoke-RestMethod @splatGetRichStudentParams -Verbose:$false

        $contractList = [System.Collections.Generic.List[object]]::new()
        foreach ($eduction in $richStudentObj.opleidingen){
            $eduction | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $eduction.sinh_id
            $contractList.Add($eduction)
        }

        $richStudentObj | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $item.studentnummer
        $richStudentObj | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value "$($item.Roepnaam) $($item.achternaam)"
        $richStudentObj | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value  $contractList

        Write-Output $richStudentObj | ConvertTo-Json -Depth 10
        Start-Sleep -MilliSeconds 10
    }
} catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorMessage = Resolve-HTTPError -ErrorObject $ex
        Write-Verbose "Could not retrieve Caci-Osiris students. Error: $errorMessage"
    } else {
        Write-Verbose "Could not retrieve Caci-Osiris students. Error: $($ex.Exception.Message)"
    }
}
