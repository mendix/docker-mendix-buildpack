get-sample:
	if [ -d build ]; then rm -rf build; fi
	if [ -d downloads ]; then rm -rf downloads; fi
	mkdir -p downloads build
	wget https://cdn.mendix.com/sample/SampleAppA.mpk -O downloads/application.mpk
	unzip downloads/application.mpk -d build/
build-image:
	docker build \
	-t mendix/mendix-buildpack:v1 .
test-container:
	tests/test-generic.sh tests/docker-compose-postgres.yml
	tests/test-generic.sh tests/docker-compose-sqlserver.yml
	tests/test-generic.sh tests/docker-compose-azuresql.yml
run-test-container:
	docker-compose -f tests/docker-compose-postgres.yml
# Build from alternative location
get-sample-alt:
	if [ -d buildalt ]; then rm -rf buildalt; fi
	if [ -d downloads ]; then rm -rf downloads; fi
	mkdir -p downloads buildalt
	wget https://cdn.mendix.com/sample/SampleAppA.mpk -O downloads/application.mpk
	unzip downloads/application.mpk -d buildalt/
build-image-alt:
	docker build \
	--build-arg BUILD_PATH=buildalt \
	-t mendix/mendix-buildpack:v1 .
