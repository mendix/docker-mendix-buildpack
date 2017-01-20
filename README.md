# Docker Mendix Buildpack

This project makes easy to deploy any Mendix app using [Docker](https://www.docker.com/) containers.

## Getting Started

* Open a terminal in your OS
* Navigate to the location where you want to checkout this project
* Execute ```git clone git@github.com:mendix/docker-mendix-buildpack.git```
* Execute ```cd docker-mendix-buildpack```
* Execute ```make get-sample```
* Execute ```make create-database```
* Execute ```make build-image```
* List the database container: ```docker ps```
* Find the database container name in the ```NAMES``` column
* Check the IP of the database executing ```docker inspect DATABASE_CONTAINTER_NAME | grep IP```
* Update the *DATABASE_ENDPOINT* with the copied IP in the Makefile run-container target: ```DATABASE_ENDPOINT=postgres://mendix:mendix@127.0.0.1:5432/mendix```
* Execute ```make run-container```
* Type in your browser http://YOUR_DOCKER_HOST_IP:8080
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

## Build Details

This was built with the following:

* Atom 1.13.0
* Docker version 1.12.5

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/mendix/IBM-Watson-Connector-Kit/tags).

## License

This project is licensed under the Apache License v2 (for details, see the [LICENSE](LICENSE-2.0.txt) file).
