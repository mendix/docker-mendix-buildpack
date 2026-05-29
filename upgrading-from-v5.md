# Upgrading from Docker Buildpack v5

Docker Buildpack v6 contains a breaking change and might require some changes in your CI/CD pipeline:

Building Mendix projects from source (\*.mpr or \*.mpk files) is now done using a build.py script.
If your CI/CD pipeline uses Docker Buildpack to build \*.mda files (compiled Mendix apps), no further changes are needed.

If you're upgrading from Docker Buildpack v4 (or an older version), you'll also need to follow the [upgrading from Docker Buildpack v4](upgrading-from-v4.md) instructions.

⚠️ If your current pipeline is failing with an _Only Ubuntu is supported_ error, your pipeline depends on CF Buildpack to build Mendix MPR files, and needs to be updated as described in this document.

## Using the build.py script

Docker Buildpack v6 no longer uses CF Buildpack to compile MPR (or MPK) files - to continue supporting newer versions of Mendix, Java and the base OS.
Instead, a custom `build.py` script will:

1. Prepare a clean [Docker context](https://docs.docker.com/build/concepts/context/) in the path specified by `--destination`. All files required to build the app image will be copied to this destination. If the directory doesn't exist, the `build.py` script will create it; if the directory is not empty, `build.py` will delete its contents.
2. Detect the file type of the source path specified by the `--source` arg (an MPK file, an MPR file, an MDA file or an unpacked MDA directory).
3. If necessary (`--source` specifies project that needs to be compiled)
   1. Create an image containing [mxbuild](https://docs.mendix.com/refguide/mxbuild/) and its dependencies.
   2. Run an `mxbuild` in a container, and copy the resulting MDA contents to the destination path specified by `--destination`.
4. Otherwise (`--source` specifies a path to an MDA file or unpacked MDA directory), `build.sh` will just copy the MDA contents to the destination path specified by `--destination`.

Once the `build.py` script runs successfully, the path specified by `--destination` will contain a Docker context and everything needed to run a `docker build` command.

### Updating an existing pipeline to use build.py

There instructions are provided as a reference, based on a typical pipeline. Your CI/CD pipeline might be different - for support with updating a custom pipeline, please check the [Mendix Support Policy](https://www.mendix.com/evaluation-guide/evaluation-learning/support/).

1. Verify your pipeline image or runner has Python 3.8 available, and uses a UNIX-like operating system (Linux, macOS or Windows Subsystem for Linux).
2. Locate the `docker build` step in your CI/CD pipeline that builds the app image. This should be the step that builds the Mendix app, and not the rootfs or its dependencies. Any `docker build` commands that build the rootfs should not be changed.
3. Before the `docker build` step, add the following lines (replacing `<path-to-source>` with the path to the project source, and `<destination-dir>` with an empty/temporary writable path):
   ```shell
   ./build.py --source <path-to-source> --destination <destination-dir> build-mda-dir
   ```
4. In the `docker build` step:
    * Remove `--build-arg BUILD_PATH` args.
    * Remove `-f` and `--file` args specifying a Dockerfile, if they exist.
    * Update the [Docker context](https://docs.docker.com/build/concepts/context/) path to the `<destination-dir>`.

After the update, your pipeline might look like this:

```shell
# Preparation steps
# Downloag Docker Buildpack
DOCKER_BUILDPACK_VERSION=v6.0.3
curl -LJ -o - https://github.com/mendix/docker-mendix-buildpack/archive/refs/tags/${DOCKER_BUILDPACK_VERSION}.tar.gz | tar --strip-components=1 -xvz
# Checkout the Mendix app source
git clone <mendix-app-git> mendix-app-src
# Build the Mendix app from mendix-app-src to a temporary location
./build.py --source mendix-app-src --destination /tmp/docker-buildpack-context build-mda-dir
# Prepare and push the Docker image, using /tmp/docker-buildpack-context as the Docker context
docker build --tag example.com/mendix-app:latest /tmp/docker-buildpack-context
docker push example.com/mendix-app:latest
# Follow-up steps
```

# Other changes

Docker Buildpack v6 switched from `ubi8` to `ubi9` images ([Red Hat Universal Base Images](https://developers.redhat.com/articles/ubi-faq)) whenever possible.
Building Mendix 8 and 9 apps still uses `ubi8`, as those versions depend on an older version of Mono that doesn't work in newer operating systems.
