########################################################################
# HelloID-Conn-Prov-Source-Caci-Osiris-Persons
#
# Version: 1.1.0
########################################################################

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$c = $configuration | ConvertFrom-Json

# Set debug logging
switch ($($c.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

# Troubleshooting
# $c.limit = 10

Write-Information "Start person import: Base URL: $($c.BaseUrl), Schoolname: $($c.SchoolName), Limit: $($c.Limit)"

# Query Persons
try {
    Write-Information 'Querying student data'

    $headers = [System.Collections.Generic.Dictionary[string, string]]::new()
    $headers.Add("Api-Key", $($c.ApiKey))

    $splatParams = @{
        Uri     = "$($c.BaseUrl)/generiek/student/zoek/?p_std_selectie=%7B%22selectie%22%3A%22$($c.SchoolName)%22%7D&limit=$($c.Limit)"
        Headers = $headers
        Method  = 'GET'
    }

    $responseStudents = Invoke-RestMethod @splatParams -Verbose:$false
    $persons = $responseStudents.items

    Write-Information "Succesfully queried student data. Result count: $($persons.count)"
}
catch {
    throw "Could not query student data. Error: $($_.Exception.Message)"
}

# Enhance and export person object to HelloID
try {
    Write-Information 'Enhancing and exporting person objects to HelloID'

    # Set counter to keep track of actual export person objects
    $exportedPersons = 0

    $persons | ForEach-Object {
        $person_ExternalId = $_.studentnummer
        # Query additional data for specific student
        try {
            $splatGetAdditionalStudentdataParams = @{
                Uri     = "$($c.BaseUrl)/basis/student?p_studentnummer=$($_.studentnummer)"
                Headers = $headers
                Method  = 'GET'
            }
            $responseAdditionalStudentdata = Invoke-RestMethod @splatGetAdditionalStudentdataParams -Verbose:$false
        }
        catch {
            throw "Could not query additional data for student: $($person_ExternalId). Error: $($_.Exception.Message)"
        }

        $person = $responseAdditionalStudentdata

        # Set required fields for HelloID
        $person | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $person.studentnummer
        $person | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value "$($person.Roepnaam) $($person.achternaam)"

        # Add opleidingen to contracts
        $contractsList = [System.Collections.ArrayList]::new()
        try {      
            $responseAdditionalStudentdata.opleidingen | ForEach-Object {
                # Set required field for HelloID
                $_ | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $_.sinh_id

                $contract_ExternalId = $_.sinh_id

                # Add opleiding data to contracts
                [Void]$contractsList.Add($_)
            }
        }
        catch {
            throw "Could not add opleidingen to contracts for student: $($person.ExternalId) for opleiding: $($contract_ExternalId). Error: $($_.Exception.Message)"
        }

        # Add Contracts to person
        if ($null -ne $contractsList) {
            ## This example can be used by the consultant if you want to filter out persons with an empty array as contract
            ## *** Please consult with the Tools4ever consultant before enabling this code. ***
            # if ($contractsList.Count -eq 0) {
            #     Write-Warning "Excluding person from export: $($person.ExternalId). Reason: Contracts is an empty array"
            #     return
            # }
            # else {
            $person | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value  $contractsList
            # }
        }
        ## This example can be used by the consultant if the date filters on the person/employment/positions do not line up and persons without a contract are added to HelloID
        ## *** Please consult with the Tools4ever consultant before enabling this code. ***    
        # else {
        #     Write-Warning "Excluding person from export: $($person.ExternalId). Reason: Person has no contract data"
        #     return
        # }
    
        # Sanitize and export the json
        $person = $person | ConvertTo-Json -Depth 10
        Write-Output $person

        # Updated counter to keep track of actual export person objects
        $exportedPersons++

        # The API is rate limited to a max of 50 requests per second.
        # Therefore; end each call with a delay of 20 milliseconds, this way it should never be more than 50 calls per second.    
        Start-Sleep -MilliSeconds 20
    }
    Write-Information "Succesfully enhanced and exported person objects to HelloID. Result count: $($exportedPersons)"
    Write-Information "Person import completed"
}
catch {
    Write-Warning "Error at line: $($_.InvocationInfo.PositionMessage)"
    throw "Error: $_"
}
