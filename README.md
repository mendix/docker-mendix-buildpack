# Introduction

This branch is an experimental attempt to reinvent the [Docker Buildpack](https://github.com/mendix/docker-mendix-buildpack) and replace CF Buildpack with custom components.

# Prerequisites

## System

This project was only tested to work in 

* Ubuntu 20.04 running in WSL2
* macOS 13

and requires:

* sh (bash or zsh)
* Docker 19.03.0+ or Podman 4
* Docker Compose 1.25.0+ (optional)

## Dependencies

# How to use it

## Build a project

Extract the project source directory.

Run the following commands (set `PROJECTSOURCE` to the path to the project root URL, e.g. `~/projects/myproject`; set `TARGETIMAGE` to the target Docker image to build, e.g. `quay.io/username/my-mx-app:latest`)
```shell
export PROJECTSOURCE=<path to project root> 
export TARGETIMAGE=<target Docker image tag>
./build.sh
```

or simply

```shell
PROJECTSOURCE=<path to project root> TARGETIMAGE=<target Docker image tag> ./build.sh
```

For example:

```shell
PROJECTSOURCE=~/projects/myproject TARGETIMAGE=quay.io/username/my-mx-app:latest ./build.sh
```

## Run the project

Run the following command (using the same `TARGETIMAGE` value as the previous step):

```shell
docker run --rm \
$TARGETIMAGE
```

To set custom configuration, use the following environment variables:

* `MX_Module_Constant` to set app constants, same as it works in Docker/CF Buildpack
* `MXRUNTIME_Variable` to set runtime variables, same as it works in Docker/CF Buildpack

For example:

```shell
docker run --rm \
-p 8080:8080 \
-e MX_MyFirstModule_MyConstant=Custom \
-e MXRUNTIME_DatabaseJdbcUrl=jdbc:hsqldb:mem:docker \
-e MXRUNTIME_DatabaseType=HSQLDB \
-e MXRUNTIME_DatabaseName=docker \
$TARGETIMAGE
```

Alternatively, you can use the docker-compose script from 

```shell
TARGETIMAGE=$TARGETIMAGE docker-compose -f docker-compose/docker-compose.yml up
```

Open http://localhost:8080 and use `Password1!` as the admin password.

## Cleanup

During the build, a temporary volume and archive will be created to store build artifacts.

If the build process is successful, these artifacts will be automatically cleaned up.

However if the build fails, you can use the `./cleanup.sh` script to remove volumes and containers from previous builds.
