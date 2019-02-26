TAG=9

all: xds echo backend client

.PHONY: backend 

backend: backend.build backend.push

backend.build:
	@echo " ---> building kat-backend image"
	@docker build . -t quay.io/datawire/kat-backend:${TAG}
	
backend.push:
	@echo " ---> pushing kat-backend image"
	@docker push quay.io/datawire/kat-backend:${TAG}


.PHONY: xds 

xds: xds.clean xds.generate 

xds.clean:
	@echo " ---> deleting generated XDS code"
	rm -rf xds/envoy && mkdir xds/envoy

xds.generate:	
	@echo " ---> generating Envoy XDS code"
	@docker build -f ${PWD}/xds/Dockerfile -t envoy-api-build .
	@docker run -it -v ${PWD}/xds/envoy:/envoy envoy-api-build:latest


.PHONY: echo 

echo: echo.clean echo.generate 

echo.clean:
	@echo " ---> deleting generated service code"
	@rm -rf $(PWD)/echo/echo.pb.go

echo.generate:	
	@echo " ---> generating echo service code"
	@docker build -f $(PWD)/echo/Dockerfile -t echo-api-build .
	@docker run -it -v $(PWD)/echo/:/echo echo-api-build:latest


.PHONY: client 

client: client.clean client.build-docker client.build 

client.clean:
	@echo " ---> deleting binaries"
	@rm -rf bin && mkdir bin

client.build-docker:
	@docker build -f $(PWD)/client/Dockerfile -t kat-client-build .	

client.build:	
	@echo " ---> building code"
	@docker run -it --rm -v $(PWD)/client/bin/:/usr/local/tmp/ kat-client-build:latest


.PHONY: sandbox

sandbox: sandbox.clean sandbox.up

sandbox.clean:
	@echo " ---> cleaning sandbox"
	@cd sandbox && docker-compose stop && docker-compose rm -f

sandbox.up:
	@echo " ---> starting sandbox"
	@cd sandbox && docker-compose up --force-recreate --abort-on-container-exit --build
