# Docker Mendix Buildpack

The Mendix Buildpack for Docker (aka docker-mendix-buildpack) provides a standard way to build and run your Mendix Application in a [Docker](https://www.docker.com/) container.

## Code Status

[![Build Status](https://travis-ci.org/mendix/docker-mendix-buildpack.svg?branch=master)](https://travis-ci.org/mendix/docker-mendix-buildpack)

## Try a sample mendix application

Open a terminal and run the following code
```
git clone https://github.com/mendix/docker-mendix-buildpack
cd docker-mendix-buildpack
make get-sample
make build-image
make run-container
```

You can now open you browser http://localhost:8080

## Uses cases scenarios:

This project is goto reference for the following scenarios :

1. Build and run a Mendix Application on your own docker set up
1. Build your Docker Image of your Mendix application, push to a container repository and run it.

## Getting started

### Requirements

* Docker (Installation [here](https://docs.docker.com/engine/installation/))
* For local testing, make sure you can run the [docker-compose command](https://docs.docker.com/compose/install/)

## Usage

### Compilation

Before running the container, it is necessary to build the image with your application. This build will also compile your application. Therefore, when you will build the Docker image you need to provide the **BUILD_PATH** parameter which indicates where the application model is located. It needs to point to the root directory of an unzipped .MDA or .MPK file. In the latter case, this is the directory where your .MPR file is located.

```
docker build --build-arg BUILD_PATH=<mendix-project-location> \
	-t mendix/mendix-buildpack:v1 .
```

### Startup

To start the container, it is required to provide the container with the password
to create a administrative account of your mendix application **ADMIN_PASSWORD**
and the **DATABASE_ENDPOINT** as you can see in the example below:

```
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://username:password@host:port/mendix \
  mendix/mendix-buildpack:v1  
```

or for Microsoft SQL server

```
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=sqlserver://username:password@host:port/mendix \
  mendix/mendix-buildpack:v1  
```

## Features

This project uses the same base technology than Mendix uses to run application in Cloud Foundry (the [mendix cloudfoundry buildpack](https://github.com/mendix/cf-mendix-buildpack)).

* Compilation of a Mendix application from project sources
* Automatic generation of the configuration (_m2ee.yaml_)
* Startup of the application when the container is spin up  
* Configured [nginx](https://nginx.org/) as reverse proxy

### Current limitations

* **PostgreSQL** and **SQLSERVER** database supported
* This setup will use a trial license for your application by default

### Enabling licensed

If you wish to start your application with a non-trial license, please provide the additional environment variables
* LICENSE_ID
* LICENSE_KEY

example:
```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e LICENSE_ID=<UUID> \
  -e LICENSE_KEY=<LICENSE_KEY> \
  mendix/mendix-buildpack:v1  
```

### Passing environment variables to your Mendix runtine

The default values for constants will be used as defined in your project. However, you can override them with environment variables. You need to replace the dot with an underscore and prefix it with MX_. So a constant like Module.Constant with value ABC123 could be set like this:

example:
```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e MX_Module_Constant=ABC123 \
  -e LICENSE_ID=<UUID> \
  -e LICENSE_KEY=<LICENSE_KEY> \
  mendix/mendix-buildpack:v1  
```

### Configuring Custom Runtime Settings

To configure any of the advanced Custom Runtime Settings you can use setting name prefixed with MXRUNTIME_ as an environment variable.

For example, to configure the ConnectionPoolingMinIdle setting to value 10, you can set the following environment variable:

example:
```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e MXRUNTIME_ConnectionPoolingMinIdle 10 \
  mendix/mendix-buildpack:v1  
```

If the setting contains a dot . you can use an underscore _ in the environment variable. So to set com.mendix.storage.s3.EndPoint to foo you can use:

```
MXRUNTIME_com_mendix_storage_s3_EndPoint foo
```

### Configuring Enabled Scheduled Events

The scheduled events can be configured using environment variable `SCHEDULED_EVENTS`.

Possible values are `ALL`, `NONE` or a comma separated list of the scheduled events that you would like to enable. For example: `ModuleA.ScheduledEvent,ModuleB.OtherScheduledEvent`

Example in a docker run command:

```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e SCHEDULED_EVENTS=ALL \
  mendix/mendix-buildpack:v1  
```

### Configuring Application log levels

Configuring log levels happens by adding one or more environment variables starting with the name `LOGGING_CONFIG` (the part of the name after that is not relevant and only used to distinguish between multiple entries if necessary). Its value should be valid JSON, in the format:

    {
      "LOGNODE": "LEVEL"
    }

You can see the available Log Nodes in your application in the Mendix Modeler. The level should be one of:
 * `CRITICAL`
 * `ERROR`
 * `WARNING`
 * `INFO`
 * `DEBUG`
 * `TRACE`


Example:

```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e LOGGING_CONFIG='{"Core": "DEBUG"}' \
  mendix/mendix-buildpack:v1  
```

## Contributions

Contributions are welcomed:

1. open an issue about your topic
1. fork, make a branch named starting with the issue number you are resolving (see [here](https://github.com/mendix/docker-mendix-buildpack/pulls?q=is%3Apr+is%3Aclosed)) and make a pull request to the master branch
1. please add some tests for feature changes

### Build Details

This was built with the following:

* Docker version 1.12.6

### Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/mendix/IBM-Watson-Connector-Kit/tags).

## License

This project is licensed under the Apache License v2 (for details, see the [LICENSE](LICENSE-2.0.txt) file).
