get-sample:
	if [ -d build ]; then rm -rf build; fi
	if [ -d downloads ]; then rm -rf downloads; fi
	mkdir -p downloads build
	wget https://cdn.mendix.com/sample/SampleAppA.mpk -O downloads/application.mpk
	unzip downloads/application.mpk -d build/
build-image:
	docker build \
	--build-arg BUILD_PATH=build \
	-t mendix/mendix-buildpack:v1 .
test-container:
	cd tests && ./test-postgres.sh
