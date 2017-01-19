get-sample:
	mkdir -p downloads build
	wget https://cdn.mendix.com/sample/SampleAppA.mpk -O downloads/application.mpk
	unzip downloads/application.mpk -d build/
create-database:
	docker run -d -e POSTGRES_USER=mendix -e POSTGRES_PASSWORD=mendix postgres
build-image:
	docker build \
	--build-arg BUID_PATH=build \
	-t mendix/mendix-buildpack:v1 .
run-container:
	docker run -it \
		-e ADMIN_PASSWORD=Password1! \
		-e DATABASE_ENDPOINT=postgres://mendix:mendix@172.17.0.2:5432/mendix \
		-p 8080:80 \
		mendix/mendix-buildpack:v1
