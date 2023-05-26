# Upgrading from Docker Buildpack v4

Docker Buildpack v5 contains some breaking changes and will require some changes in your CI/CD pipeline:

* rootfs images are no longer published to Docker Hub.
* rootfs images are now based on [Red Hat Universal Base Image 8 minimal](https://developers.redhat.com/articles/ubi-faq) image.
* CF Buildpack is packaged directly into the build image.
* Mendix 7 and older versions are no longer supported. To use Docker Buildpack v5, upgrade your app to Mendix 8 or a later version.

## Building rootfs images

In the past, Docker Buildpack offered two types of rootfs images: `bionic` and `ubi8`.

* `bionic` images were based on Ubuntu 18.04 and were primarily used during the build phase - although it was also possible to build an app based on `bionic` by specifying a custom `--build-arg ROOTFS_IMAGE=mendix/rootfs:bionic` argument.
* `ubi8` images were based on Red Hat UBI8 minimal and contained only components that are required to run a Mendix app.

With Docker Buildpack v5, all images are now based on ubi8-minimal:

* `app` images contain only components that are required to run an app. Build-time components such as `tar`, compilers or Mono prerequisites are excluded - reducing the image size and excluding components that could increase the number of unpatched CVEs in the final image
* `builder` images contain CF Buildpack and additional components that are only required when compiling a Mendix app.

You will need to update your pipelines to build these prerequisite images and (optionally) push them to your private registry.

### Option 1: build rootfs images on every build

If your build system uses a shared or local Docker instance with cache enabled, you can build the rootfs images on every build.
The local cache will skip rebuilding rootfs images if they've already been built previously.

In this case, your build pipeline needs to be adjusted:

1. Before building a Mendix app, build the rootfs images:
   ```shell
   docker build -t mendix-rootfs:app -f rootfs-app.dockerfile .
   docker build -t mendix-rootfs:builder -f rootfs-builder.dockerfile .
   ```
2. When building the Mendix app itself, use the default values for `ROOTFS_IMAGE` and `BUILDER_ROOTFS_IMAGE` (remove any custom `--build-arg ROOTFS_IMAGE=...` and `--build-arg BUILDER_ROOTFS_IMAGE=...` arguments from the `docker build` command)
3. If you need to use a specific version of CF Buildpack via `CF_BUILDPACK` or `CF_BUILDPACK_URL` arguments, these arguments should be specified when building the `rootfs-builder.dockerfile` image, **not** your app image.

### Option 2: build rootfs images centrally

If your build system doesn't have a shared Docker instance, building rootfs images would be a better choice.

In this case, you need to make the following changes in your CI/CD process:

1. Create a CI/CD job that builds the rootfs images and pushes them to your private registry:
   ```shell
   docker build -t {your-private-registry}/mendix-rootfs:app -f rootfs-app.dockerfile .
   docker push -t {your-private-registry}/mendix-rootfs:app
   docker build -t {your-private-registry}/mendix-rootfs:builder -f rootfs-builder.dockerfile .
   docker push -t {your-private-registry}/mendix-rootfs:builder
   ```
   This CI/CD job can run periodically (for example, every 24 hours) or when a CVE scanner detects that a new patch is available.
2. In the CI/CD job, replace (or add) build args to use rootfs images from your private registry (in this example, `--build-arg ROOTFS_IMAGE={your-private-registry}/mendix-rootfs:app` and `--build-arg BUILDER_ROOTFS_IMAGE={your-private-registry}/mendix-rootfs:builder` specify to use the images built in step 1), for example:
   ```shell
   docker build \
   --build-arg BUILD_PATH=<mendix-project-location> \
   --build-arg ROOTFS_IMAGE={your-private-registry}/mendix-rootfs:app \
   --build-arg BUILDER_ROOTFS_IMAGE={your-private-registry}/mendix-rootfs:builder \
   --tag {your-private-registry}/my-app:latest .
   ```
3. If you need to use a specific version of CF Buildpack via `CF_BUILDPACK` or `CF_BUILDPACK_URL` arguments, these arguments should be specified when building the `rootfs-builder.dockerfile` image, **not** your app image.

## Migrating from Ubuntu to Red Hat UBI

Ubuntu 18.04 Bionic is no longer supported and will no longer receive CVE patches or other updates.

Docker Buildpack switched to Red Hat UBI8, since it's a de facto standard for enterprise applications.
UBI8 will receive security updates [until 2029](https://access.redhat.com/support/policy/updates/errata/#RHEL8_Planning_Guide).

If your container requires additional binary packages, you will need to replace any Ubuntu packages with their RHEL alternatives.
