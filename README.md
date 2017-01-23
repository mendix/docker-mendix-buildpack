# Docker Mendix Buildpack

This project makes easy to deploy any Mendix app using [Docker](https://www.docker.com/) containers.

## Getting Started

* Open a terminal in your OS
* Navigate to the location where you want to checkout this project
* Clone this project ```git clone git@github.com:mendix/docker-mendix-buildpack.git```
* Go to project folder ```cd docker-mendix-buildpack```
* Download an example app ```make get-sample```
* Build ```make build-image```
* Execute ```make run-container```

* Type in your browser http://localhost:8080
* **Congratulations, you made it!**

### Prerequisities

* Docker (Installation [here](https://docs.docker.com/engine/installation/))

### Features

Because internally the image uses [CF Mendix Buildpack](https://github.com/mendix/cf-mendix-buildpack), we bring the following features:  

* Compilation of the Mendix app in the image
* Automatic generation of the ```m2ee.yaml```
* Startup of the app when the container is spin up  
* Configured [nginx](https://nginx.org/) as reverse proxy

> In future releases we will support more features like the configuration of constants or the Java heap size. Please check the [CF Buildpack](https://github.com/mendix/cf-mendix-buildpack)

## Installation

### Compilation

Before to run the container, it is necessary to build the image with your app as a result of the compilation. Therefore, when you will build the Docker image you need to provide the **BUILD_PATH** parameter which indicates where the app's source code is located.

```
docker build --build-arg BUID_PATH=change_this_value \
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

## Known limitations

* The only database supported is **PostgreSQL**
* It is not supported the change of constant default values

## Build Details

This was built with the following:

* Atom 1.13.0
* Docker version 1.12.5

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/mendix/IBM-Watson-Connector-Kit/tags).

## License

This project is licensed under the Apache License v2 (for details, see the [LICENSE](LICENSE-2.0.txt) file).
