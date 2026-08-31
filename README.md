# HelloID-Conn-Prov-Source-Caci-Osiris

> [!CAUTION]
> The customer must manually select the relevant data fields in Osiris. By default, all data is available, including BSN and other fields that we do not want to include in HelloID.
Make sure to clearly communicate this to the customer, and always perform a preview of the data first to check if any unexpected fields are included.

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<br />
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/osiris-logo.png">
</p>

## Table of contents

- [HelloID-Conn-Prov-Source-Caci-Osiris](#helloid-conn-prov-source-caci-osiris)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
      - [Rate limiting](#rate-limiting)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Source-Caci-Osiris_ is a _source_ connector. Caci-Osiris provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint                | Description                                        |
| ----------------------- | -------------------------------------------------- |
| /basis/student          | Used to retrieve the students                      |
| /generiek/student       | Used to retrieve the student education information |
| /generiek/student/zoek/ | Used to retrieve the student education information |

When classes and groups needs to be included the additional API endpoint are necessary

| Endpoint                       | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| /generiek/studentgroep         | Used to retrieve the groups / classed education information              |
| /generiek/studentgroep/student | Used to retrieve the student from groups / classed education information |


## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting    | Description                                                                           | Mandatory |
| ---------- | ------------------------------------------------------------------------------------- | --------- |
| BaseUrl    | The URL to Caci Osiris.                                                               | Yes       |
| ApiKey     | The ApiKey to connector to Caci Osiris. ApiKeys are generated within the application. | Yes       |
| SchoolName | The name of the school for which the data will be fetched                             | Yes       |
| Limit      | The limit of students that will be fetched from Caci Osiris and imported in HelloID   | Yes       |
| Isdebug    | When toggled, debug logging will be displayed                                         | No        |

### Prerequisites

- [ ] Enable the webservices

### Remarks



#### Rate limiting

Currently the _HelloID-Conn-Prov-Source-Caci-Osiris_ connector works as follows:

1. First retrieve all students from Caci Osiris using a `GET /studenten`.
2. For each student; we have to do a `GET /studenten/studentNummer` to get a 'so called' `richStudent` object containing information about the educations.

So, if an organization has a large number of students, a lot of API calls will have to be made. 

The Caci Osiris API is rate limited to a max of 50 requests per second. Therefore; 

1. First we retrieve all students and store them in the `$responseStudents` object.

```powershell
  $responseStudents = Invoke-RestMethod @splatParam
```

2. For each individual student we will fetch the `richStudentData` data from Caci Osiris with a 1 second interval between each batch.

```powershell
  $persons | ForEach-Object {
    $splatGetAdditionalStudentdataParams = @{
        Uri     = "$($config.BaseUrl)/basis/student?p_studentnummer=$($_.studentnummer)"
        Headers = $headers
        Method  = 'GET'
    }
    $responseAdditionalStudentdata = Invoke-RestMethod @splatGetRichStudentParams -Verbose:$false
    ...
    Start-Sleep -Seconds 20
  }
```

## Setup the connector

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/Source-systems/powershell-v2-Source-systems.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
