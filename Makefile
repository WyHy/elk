REGISTRY           := ccr.ccs.tencentyun.com
NAMESPACE          := wangy
PODNAME            := elasticsearch
REGISTRYUSERNAME   := 100012377990
include .env
TAG                := $$(git rev-parse --verify HEAD)#you can change the git HEAD to use the specific images

all: build run ps log

env:
	@echo "" > .env
	@echo "ENVFLAG=${ENVFLAG}" >> .env
	@echo "TAG=${TAG}" >> .env
	@echo "REGISTRY=${REGISTRY}" >> .env
	@echo "NAMESPACE=${NAMESPACE}" >> .env
	@echo "PODNAME=${PODNAME}" >> .env


build:
	@docker-compose -f docker-compose-${ENVFLAG}.yaml build

ps:
	@docker-compose -f docker-compose-${ENVFLAG}.yaml ps

run-build: build
	@docker-compose -f docker-compose-${ENVFLAG}.yaml up -d
	make ps
	make log

run:
	@docker-compose -f docker-compose-${ENVFLAG}.yaml up -d
	make ps
	make log

exec:
	@docker exec -it $$(make ps | awk '{print $$1}' | sed -n '/${p}/p') ${cmd}

log:
	@docker-compose -f docker-compose-${ENVFLAG}.yaml logs -f $(PODNAME)

status:
	@docker stats

push: env build
	@docker-compose -f docker-compose-${ENVFLAG}.yaml push

pull: env
	@docker-compose -f docker-compose-${ENVFLAG}.yaml pull

down:
	@docker-compose -f docker-compose-${ENVFLAG}.yaml down

config:
	cp ./hosts /etc/hosts

login:
	@echo "password for sudo"
	@echo "then password for registry user ${REGISTRYUSERNAME}"
	sudo docker login --username=${REGISTRYUSERNAME} ${REGISTRY}

deploy: login pull run-without-build ps log

quik-fix:
	git add .
	git commit -m "fix(quik): fix something and quik test it"
	git push

quik-deploy:
	git pull
	make pull
	make run-without-build
	make ps
	make log

quik-push: build quik-fix push

clean:
	black .

release-env:
	@echo "" > .env
	@echo "ENVFLAG=release" >> .env
	@echo "TAG=${VERSION}" >> .env
	@echo "REGISTRY=${REGISTRY}" >> .env
	@echo "NAMESPACE=${NAMESPACE}" >> .env
	@echo "PODNAME=${PODNAME}" >> .env

release-push: release-env build
	@docker-compose -f docker-compose-${ENVFLAG}.yaml push

release-pull: release-env
	@docker-compose -f docker-compose-${ENVFLAG}.yaml pull

release-run: release-pull run
