# Docker Mendix Buildpack

![Test status](https://github.com/mendix/docker-mendix-buildpack/workflows/Test/badge.svg)

The Mendix Buildpack for Docker (aka docker-mendix-buildpack) provides a standard way to build and run your Mendix Application in a [Docker](https://www.docker.com/) container.

## Try a sample mendix application

Open a terminal and run the following code:

> Important note: always provide `<TAG>` value to guarantee consistent builds. List of tags is available [here](https://github.com/mendix/docker-mendix-buildpack/tags).

```
git clone --branch <TAG> --config core.autocrlf=false https://github.com/mendix/docker-mendix-buildpack
cd docker-mendix-buildpack
make get-sample
make build-image
make run-container
```

You can now open your browser [http://localhost:8080]([http://localhost:8080])

## Uses cases scenarios:

This project is a goto reference for the following scenarios :

1. Build and run a Mendix Application on your own docker set up
2. Build the Docker Image of your Mendix application, push to a container repository and run it.

## Getting started

### Requirements

* Docker 17.05 (Installation [here](https://docs.docker.com/engine/installation/))
  * Earlier Docker versions are no longer compatible because they don't support multistage builds.
    To use Docker versions below 17.05, download an earlier Mendix Docker Buildpack release, such as [v2.3.2](https://github.com/mendix/docker-mendix-buildpack/releases/tag/v2.3.2)
* For preparing, a local installation of wget (for macOS)
* For local testing, make sure you can run the [docker-compose command](https://docs.docker.com/compose/install/)

## Usage

### Compilation

Before running the container, it is necessary to build the image with your application. This buildpack contains Dockerfile with a script that will compile your application using [cf-mendix-buildpack](https://github.com/mendix/cf-mendix-buildpack/).

```
docker build 
  --build-arg BUILD_PATH=<mendix-project-location> \
  --build-arg ROOTFS_IMAGE=<root-fs-image-tag> \
  --build-arg BUILDER_ROOTFS_IMAGE=<root-fs-image-tag> \
  --build-arg CF_BUILDPACK=<cf-buildpack-version> \
  --tag mendix/mendix-buildpack:v1.2 .
```

For build you can provide next arguments:

- **BUILD_PATH** indicates where the application model is located. It is a root directory of an unzipped .MDA or .MPK file. In the latter case, this is the directory where your .MPR file is located. Must be within [build context](https://docs.docker.com/engine/reference/commandline/build/#extended-description). Defaults to `./project`.
- **ROOTFS_IMAGE** is a type of rootfs image. Defaults to `mendix/rootfs:ubi8` (Red Hat Universal Base Image 8). To use Ubuntu 18.04, change this to `mendix/rootfs:bionic`. It's also possible to use a custom rootfs image as described in [Advanced feature: full-build](#advanced-feature-full-build).
- **BUILDER_ROOTFS_IMAGE** is a type of rootfs image used for downloading the Mendix app dependencies and compiling the Mendix app from source. Defaults to `mendix/rootfs:bionic`. It's also possible to use a custom rootfs image as described in [Advanced feature: full-build](#advanced-feature-full-build).
- **CF_BUILDPACK** is a version of CloudFoundry buildpack. Defaults to `v4.15.4`. For stable pipelines, it's recommended to use a fixed version from **v4.15.4** and later. CloudFoundry buildpack versions below **v4.15.4** are not supported.
- **EXCLUDE_LOGFILTER** will exclude the `mendix-logfilter` binary from the resulting Docker image if set to `true`. Defaults to `true`. Excluding `mendix-logfilter` will reduce the image size and remove a component that's not commonly used; the `LOG_RATELIMIT` environment variable option will be disabled.
- **UNINSTALL_BUILD_DEPENDENCIES** will uninstall packages which are not needed to launch an app, and are only used during the build phase. Defaults to `true`. This option will remove several libraries which are known to have unpatched CVE vulnerabilities.
- **CF_BUILDPACK_URL** specifies the URL where the CF buildpack should be downloaded from (for example, a local mirror). Defaults to `https://github.com/mendix/cf-mendix-buildpack/releases/download/${CF_BUILDPACK}/cf-mendix-buildpack.zip`. Specifying **CF_BUILDPACK_URL** will override the version from **CF_BUILDPACK**.
- **BLOBSTORE** can be used to specify an alternative buildpack resource server (instead of the default Mendix CDN). For more information, see the [CF Buildpack offline settings](https://github.com/mendix/cf-mendix-buildpack#offline-buildpack-settings).
- **BUIDPACK_XTRACE** can be used to enable CF Buildpack [debug logging](https://github.com/mendix/cf-mendix-buildpack#logging-and-debugging). Set this variable to `true` to enable debug logging.

### Startup

To start the container, it is required to provide the container with the password
to create an administrative account of your mendix application **ADMIN_PASSWORD**
and the **DATABASE_ENDPOINT** as you can see in the example below:

```
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://username:password@host:port/mendix \
  mendix/mendix-buildpack:v1.2  
```

or for Microsoft SQL server

```
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=sqlserver://username:password@host:port/mendix \
  mendix/mendix-buildpack:v1.2  
```

Alternative ways to configure database connection:

* `DATABASE_URL` environment variable

```
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_URL=sqlserver://username:password@host:port/mendix \
  mendix/mendix-buildpack:v1.2  
```

* [Custom runtime settings](https://github.com/mendix/cf-mendix-buildpack/#configuring-custom-runtime-settings)

```
// full config
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e MXRUNTIME_DatabaseType=MYSQL \
  -e MXRUNTIME_DatabaseUserName=mendix \
  -e MXRUNTIME_DatabasePassword=mendix \
  -e MXRUNTIME_DatabaseName=mendix \
  -e MXRUNTIME_DatabaseHost=host:port \
  mendix/mendix-buildpack:v1.2  

// config with jdbc url
docker run -it \
  -e ADMIN_PASSWORD=Password1! \
  -e MXRUNTIME_DatabaseType=MYSQL \
  -e MXRUNTIME_DatabaseUserName=mendix \
  -e MXRUNTIME_DatabasePassword=mendix \
  -e MXRUNTIME_DatabaseJdbcUrl=mysql://db:3306/mendix \
  -e MXRUNTIME_DatabaseName=mendix \
  mendix/mendix-buildpack:v1.2  
```

## Features

This project uses the same base technology that Mendix uses to run the application in Cloud Foundry (the [mendix cloudfoundry buildpack](https://github.com/mendix/cf-mendix-buildpack)).

* Compilation of a Mendix application from project sources
* Automatic generation of the configuration (_m2ee.yaml_)
* Startup of the application when the container is spin up  
* Configured [nginx](https://nginx.org/) as the reverse proxy

### Current limitations

* **PostgreSQL** and **SQLSERVER** database supported
* This setup will use a trial license for your application by default

### Enabling License

If you wish to start your application with a non-trial license, please provide the additional environment variables:

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
  mendix/mendix-buildpack:v1.2  
```

### Passing environment variables to your Mendix runtime

The default values for constants will be used as defined in your project. However, you can override them with environment variables. You need to replace the dot with an underscore and prefix it with MX_. So a constant like Module. Constant with value ABC123 could be set like this:

example:

```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e MX_Module_Constant=ABC123 \
  -e LICENSE_ID=<UUID> \
  -e LICENSE_KEY=<LICENSE_KEY> \
  mendix/mendix-buildpack:v1.2  
```

Two ways to pass multi-line environment variable:
1. Command line - when **docker run** executed, it's possible to pass multi-line value with double quotes 
```
docker run -it \
  -e CERTIFICATE_AUTHORITIES="-----BEGIN CERTIFICATE-----
                MIIGejCCBGKgAwIBAgIJANuKwREDEb4sMA0GCSqGSIb3DQEBCwUAMIGEMQswCQYD
                VQQGEwJOTDEVMBMGA1UECBMMWnVpZC1Ib2xsYW5kMRIwEAYDVQQHEwlSb3R0ZXJk
                YW0xDzANBgNVBAoTBk1lbmRpeDEXMBUGA1UEAxMOTWVuZGl4IENBIC0gRzIxIDAe..."
```
2. Docker-compose - special prefix can be used
```
environment:
    CERTIFICATE_AUTHORITIES: |-
                -----BEGIN CERTIFICATE-----
                MIIGejCCBGKgAwIBAgIJANuKwREDEb4sM....
```

Requested a test scenario from Jouke and Xiwen, meanwhile will update docker-buildpack documentation.

### Configuring Custom Runtime Settings

To configure any of the advanced [Custom Runtime Settings](https://world.mendix.com/display/refguide6/Custom+Settings) you can use setting name prefixed with `MXRUNTIME_` as an environment variable.

For example, to configure the ConnectionPoolingMinIdle setting to value 10, you can set the following environment variable:

Example:

```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e MXRUNTIME_ConnectionPoolingMinIdle 10 \
  mendix/mendix-buildpack:v1.2  
```

If the setting contains a dot . you can use an underscore _ in the environment variable. So to set com.mendix.storage.s3.EndPoint to foo you can use:

```
MXRUNTIME_com_mendix_storage_s3_EndPoint foo
```

### Configuring Enabled Scheduled Events

The scheduled events can be configured using environment variable `SCHEDULED_EVENTS`.

Possible values are `ALL`, `NONE` or a comma separated list of the scheduled events that you would like to enable. For example: `ModuleA.ScheduledEvent.ModuleB.OtherScheduledEvent`

An example in a docker run command:

```
docker run -it \
  -p 8080:80 \
  -e ADMIN_PASSWORD=Password1! \
  -e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
  -e SCHEDULED_EVENTS=ALL \
  mendix/mendix-buildpack:v1.2  
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
  mendix/mendix-buildpack:v1.2  
```
### Monitoring the runtime

The admin interface can be used to measure the health of the Runtime as per [documentation](https://docs.mendix.com/refguide/monitoring-mendix-runtime). The password of the admin port can be set using the environment variable M2EE_PASSWORD. The standard username is MxAdmin. The interface is exposed to the outside world on the url /_mxadmin/ and can be accessed by using basic HTTP authentication. Refer to the [documentation](https://docs.mendix.com/refguide/monitoring-mendix-runtime) to learn how to use this interface.

To clarify: 
- the HTTP basic authentication credentials are: MxAdmin / [M2EE_PASSWORD] .
- the X-M2EE-Authentication header contains a base64-encoded version of [M2EE_PASSWORD] .

### Health check

The docker compose files, in the ```/test``` folder, contain an example how to perform a healtcheck on a Mendix app:

```
healthcheck:
            test: ["CMD", "curl", "-f", "http://localhost"]
            interval: 15s
            retries: 2
            start_period: 10s
            timeout: 3s
```

The health check monitors the status of the Mendix container, but it does not autoheal or restarts the container in case of unhealthy status, relying on the Docker runtime to perform the aforementioned task. For instance, Kubernetes is in charge to restart the unhealthy containers, but reporting their status it is a responsibility of the containers themselves. For a Kubernetes example, please follow this [link](https://github.com/mendix/kubernetes-howto/blob/master/mendix-app.yaml).

For further information, the official documentation [here](https://docs.docker.com/engine/reference/builder/#healthcheck).

### Certificate Management


Certificate Authorities (CAs) can be managed using the CERTIFICATE_AUTHORITIES environment variable, see the upstream [Cloud Foundry Build Pack documentation](https://github.com/mendix/cf-mendix-buildpack#certificate-management). 

In case your environment does not support multi-line environment variables, a Base64-encoded string containing the desired CA Certificates can be used alternatively. 

This string should be set into the CERTIFICATE_AUTHORITIES_BASE64 environment variable.

### Advanced feature: full-build

To save build time, the build pack will normally use a pre-built rootfs from Docker Hub. This rootfs is prepared nightly by Mendix using [this](https://github.com/mendix/docker-mendix-buildpack/blob/master/Dockerfile.rootfs.bionic) Dockerfile. If you want to build the root-fs yourself you can use the following script:

```
docker build --build-arg BUILD_PATH=<mendix-project-location> \
	-t <root-fs-image-tag> -f Dockerfile.rootfs.bionic .
```

After that you can build the target image with the next command:

```
docker build 
  --build-arg BUILD_PATH=<mendix-project-location> \
  --build-arg ROOTFS_IMAGE=<root-fs-image-tag> \
  --build-arg BUILDER_ROOTFS_IMAGE=<builder-root-fs-image-tag> \
	-t mendix/mendix-buildpack:v1.2 .
```

## Contributions

Contributions are welcomed:

1. open an issue about your topic
2. fork, make a branch named starting with the issue number you are resolving (see [here](https://github.com/mendix/docker-mendix-buildpack/pulls?q=is%3Apr+is%3Aclosed)) and make a pull request to the master branch
3. please add some tests for feature changes

### Build Details

This was built with the following:

* Docker version 18.06.3

### Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/mendix/IBM-Watson-Connector-Kit/tags).

## License

This project is licensed under the Apache License v2 (for details, see the [LICENSE](LICENSE-2.0.txt) file).
