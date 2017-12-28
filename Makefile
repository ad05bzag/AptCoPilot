NAME=AptCoPilot
CURRENT=${CURDIR}
DEST=/go/src/github.com/HLJman/$(NAME)
INSTANCE=13.57.189.227

default: fmt vet build

# Build
build:
	go build -ldflags "-s" -o $(NAME)

fmt: 
	go fmt $$(go list ./... | grep -v /vendor/)

vet:
	go vet $$(go list ./... | grep -v /vendor/)

run: docker_build
	docker run --rm -it \
	-p 8000:8000 \
	hljman/aptcopilot
	# -e DB_USERNAME=jadmin \
	# -e DB_PASSWORD=/etc/db_password \
	# -e DB_SERVER=database:8889 \
	# -e DB_NAME=copilot \


docker_build:
	docker run --rm -e "CGO_ENABLED=0" -e "GOPATH=/go" -v "$(CURRENT):$(DEST)" -w "$(DEST)" golang:1.9.2 make
	docker build -t hljman/aptcopilot .

assets_build:
	cd assets; polymer build

upload:
	scp -rv -i ~/.ssh/aws aptcopilot.tgz ubuntu@$(INSTANCE):/home/ubuntu/

ssh: 
	ssh -i ~/.ssh/aws ubuntu@$(INSTANCE)

ssh_and_reload: 
	ssh -i ~/.ssh/aws ubuntu@$(INSTANCE) "gunzip -c aptcopilot.tgz | docker load && docker-compose up -d"

docker_zip: assets_build docker_build
	docker save hljman/aptcopilot | gzip > aptcopilot.tgz


publish: docker_zip upload ssh_and_reload