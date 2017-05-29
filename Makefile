get-sample:
	if [ -d build ]; then rm -rf build; fi
	if [ -d downloads ]; then rm -rf downloads; fi
	mkdir -p downloads build
	wget https://cdn.mendix.com/sample/SampleAppA.mpk -O downloads/application.mpk
	unzip downloads/application.mpk -d build/

build-image:
	docker build \
	--build-arg BUILD_PATH=build \
	-t mendix/mendix-buildpack:v1.2 .

test-container:
	tests/test-generic.sh tests/docker-compose-postgres.yml
	tests/test-generic.sh tests/docker-compose-sqlserver.yml
	tests/test-generic.sh tests/docker-compose-azuresql.yml

run-container:
	docker-compose -f tests/docker-compose-postgres.yml up
