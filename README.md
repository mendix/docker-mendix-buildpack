# Docker Mendix Buildpack

The Mendix Buildpack for Docker (aka docker-mendix-buildpack) provides a standard way to build and run your Mendix Application in a [Docker](https://www.docker.com/) container.

## Code Status

[![Build Status](https://travis-ci.org/mendix/docker-mendix-buildpack.svg?branch=master)](https://travis-ci.org/mendix/docker-mendix-buildpack)

## Try a sample mendix application

Open a terminal and run the following code
```
git clone git@github.com:mendix/docker-mendix-buildpack.git
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

Before to run the container, it is necessary to build the image with your app as a result of the compilation. Therefore, when you will build the Docker image you need to provide the **BUILD_PATH** parameter which indicates where the app's source code is located.

```
docker build --build-arg BUILD_PATH=<mendix-project-location> \
	-t mendix/mendix-buildpack:v1 .
```

### Startup

To start the container, it is required to provide the container with the password
to create a administrative account **ADMIN_PASSWORD** and the **DATABASE_ENDPOINT**
as you can see in the command below:

```
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  mendix/mendix-buildpack:v1  
```

## Features

This project uses the same base technology than Mendix uses to run application in Cloud Foundry (the [mendix cloudfoundry buildpack](https://github.com/mendix/cf-mendix-buildpack)).

* Compilation of a Mendix application from project sources
* Automatic generation of the configuration (_m2ee.yaml_)
* Startup of the application when the container is spin up  
* Configured [nginx](https://nginx.org/) as reverse proxy

### Current limitations

* **PostgreSQL** database supported
* This setup will use a trial license for your application

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


## Contributions

Contributions are welcomed:

1. open an issue about your topic
1. fork, make a branch named starting with the issue number you are resolving (see [here](https://github.com/mendix/docker-mendix-buildpack/pulls?q=is%3Apr+is%3Aclosed)) and make a pull request to the master branch
1. please add some tests for feature changes

### Build Details

This was built with the following:

* Atom 1.13.0
* Docker version 1.12.6

### Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/mendix/IBM-Watson-Connector-Kit/tags).

## License

This project is licensed under the Apache License v2 (for details, see the [LICENSE](LICENSE-2.0.txt) file).
