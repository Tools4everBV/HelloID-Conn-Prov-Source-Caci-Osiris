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

function ConvertTo-Batches {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [object[]]
        $InputArray,

        [int]
        $BatchSize
    )

    $batchArray = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt $InputArray.Count; $i+= $BatchSize) {
        if (($InputArray.Count - $i) -gt $BatchSize-1  ) {
            $null = $batchArray.add($InputArray[$i..($i + $BatchSize-1)])
        } else {
            $null = $batchArray.add($InputArray[$i..($InputArray.Count - 1)])
        }
    }
    $batchArray
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

    # The API is rate limited to a max of 50 requests per second. Therefore; we break down the students received in the
    # $responseStudents object and separate them into batches. The size of a individual batch can be specified in the configuration
    # but must not exceed the limit of 50.
    #
    # For each individual batch we will fetch the 'richStudentData' with 1 second of wait time between each batch.

    Write-Verbose "Retrieving RichStudentObject in batches of [$($config.batchSize)]"
    $batches = ConvertTo-Batches -InputArray $responseStudents.items -BatchSize $($config.batchSize)
    $studentList = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $batches.count; $i++) {
        foreach ($item in $batches[$i]) {
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

            $student = [PSCustomObject]@{
                ExternalId  = $item.studentnummer
                DisplayName = "$($item.Roepnaam) $($item.achternaam)"
                Student     = $student
                RichStudent = $richStudentObj
                Contracts   = $contractList
            }
            $studentList.Add($student)
        }
        Start-Sleep -Seconds 1
    }

    foreach ($person in $studentList){
        Write-Output $person | ConvertTo-Json -Depth 60
    }
} catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorMessage = Resolve-HTTPError -ErrorObject $ex
        Write-Verbose "Could not retrieve Caci-Osiris employees. Error: $errorMessage"
    } else {
        Write-Verbose "Could not retrieve Caci-Osiris employees. Error: $($ex.Exception.Message)"
    }
}
