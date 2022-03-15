# HelloID-Conn-Prov-Source-Caci-Osiris

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

> :warning: This connector can only be used in conjunction with the HelloID provisioning agent.<br />
> :warning: This connector has not been tested on a HelloID environment.<br />
<br />

<p align="center">
  <img src="https://www.caci.nl/wp-content/themes/caci-bootscore-child/img/logo/logo.svg" width="400">
</p>

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Prerequisites](#Prerequisites)
  + [Remarks](#Remarks)
- [Setup the connector](@Setup-The-Connector)
- [Getting help](#Getting-help)
- [HelloID Docs](#HelloID-docs)

## Introduction

_HelloID-Conn-Prov-Source-Caci-Osiris_ is a _source_ connector. Caci-Osiris provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint     | Description |
| ------------ | ----------- |
| /basis/student | Used to retrieve the students |
| /generiek/student | Used to retrieve the student education information |

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                        | Mandatory   |
| ------------ | -----------                        | ----------- |
| BaseUrl    |The URL to Caci Osiris. | Yes |
| ApiKey     | The ApiKey to connector to Caci Osiris. ApiKeys are generated within the application. | Yes |
| SchoolName | The name of the school for which the data will be fetched | Yes |
| Limit      | The limit of students that will be fetched from Caci Osiris and imported in HelloID | Yes |
| BatchSize  | The rate limit used to fetch the data. Set this to a max value of 50. The default value is set to '40' | No |
| Isdebug    | When toggled, debug logging will be displayed | No |

### Prerequisites

- [ ] HelloID Provisioning agent.
- [ ] Windows PowerShell 5.1 installed on the server where the HelloID agent is installed.

### Remarks

#### HelloID Agent

For this connector to work properly, you will need to use this connector in conjunction with the HelloID provisioning agent. 

> This connector will not work properly when executed using the cloud. 

#### Not tested

This connector has not been tested on a HelloID environment. Changes might have to be made to the code according to your needs.

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

2. Then; we break down the students received in the `$responseStudents` object and separate them into smaller batches. The size of each individual batch can be specified in the configuration (The default value is set to 40) but must not exceed the limit of 50. 

```powershell
  $batches = ConvertTo-Batches -InputArray $responseStudents.items -BatchSize $($config.batchSize)
```

3. For each individual batch we will fetch the `richStudentData` data from Caci Osiris with a 1 second interval between each batch.

```powershell
  foreach ($item in $batches[$i]) {
    $splatGetRichStudentParams = @{
        Uri     = "$($config.BaseUrl)/basis/student?p_studentnummer=$($item.studentnummer)"
        Headers = $headers
        Method  = 'GET'
    }
    $richStudentObj = Invoke-RestMethod @splatGetRichStudentParams -Verbose:$false
    ...
    Start-Sleep -Seconds 1
  }
```

#### No mapping

Since this connector has not been tested on a HelloID environment, a student mapping is not provided. 

## Setup the connector

## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
