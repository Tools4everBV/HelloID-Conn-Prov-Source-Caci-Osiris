# HelloID-Conn-Prov-Source-Caci-Osiris

> :warning: This connector has not been tested on a HelloID environment.

<p align="center">
  <img src="https://www.caci.nl/wp-content/themes/caci-bootscore-child/img/logo/logo.svg">
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
| /basis/studenten | Used to retrieve the students |
| /generiek/student/opleiding | Used to retrieve the student education information |

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                        | Mandatory   |
| ------------ | -----------                        | ----------- |
| ApiKey     | The ApiKey to connector to Caci Osiris. ApiKeys are generated within the application. | Yes |
| BaseUrl     |The URL to Caci Osiris. | Yes |
| Limit      | The rate limit used to fetch the data. | Yes |

### Prerequisites

### Remarks

#### Not tested

This connector has not been tested on a HelloID environment. Changes might have to be made to the code according to your needs.

#### No mapping

Since this connector has not been tested on a HelloID environment, a student mapping is not provided. 

## Setup the connector

## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
