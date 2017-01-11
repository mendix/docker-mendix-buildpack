clean-images:
	docker ps --filter "status=exited" | xargs --no-run-if-empty docker rm
create-database:
	docker run -d -e POSTGRES_USER=mendix -e POSTGRES_PASSWORD=mendix postgres
build-image:
	docker build \
	--build-arg BUID_PATH=build \
	--build-arg CACHE_PATH=cache \
	--build-arg VCAP_SERVICES="{ \
	  \"PostgreSQL\": [ \
	         { \
	          \"credentials\": { \
	                 \"host\": \"127.0.0.1\", \
	                 \"hostname\": \"127.0.0.1\", \
	                 \"name\": \"mendix\", \
	                 \"password\": \"mendix\", \
	                 \"port\": \"5432\", \
	                 \"uri\": \"postgres://mendix:mendix@127.0.0.1:5432/mendix\", \
	                 \"user\": \"mendix\", \
	                 \"username\": \"mendix\" \
	          }, \
	          \"label\": \"postgresql\", \
	          \"name\": \"mendix\", \
	          \"plan\": \"100\", \
	          \"provider\": \"core\", \
	          \"syslog_drain_url\": null, \
	          \"tags\": [] \
	         } \
		  ] \
		 }" \
	-t mendix/mendix-buildpack:v1 .
run-container:
	docker run -it \
	  -e VCAP_APPLICATION="{ \
			\"application_name\": \"docker_example\", \
			\"application_uris\": [\"docker_example.com\"], \
			 \"limits\": { \
				\"disk\": 1024, \
				\"fds\": 16384, \
				\"mem\": 1024 \
			 } \
		 }" \
		-e ADMIN_PASSWORD=Password1! \
		mendix/mendix-buildpack:v1
get-sample:
	wget https://cdn.mendix.com/sample/SampleAppA.mpk -O downloads/application.mpk
	unzip downloads/application.mpk -d build/
