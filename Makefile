HOST_GOOS     ?= $(shell go env GOHOSTOS)
HOST_GOARCH   ?= $(shell go env GOHOSTARCH)
VERSION       ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo dev)-$(shell git rev-parse --short HEAD)
BIN_NAME      ?= $(shell basename -s .git $(shell git remote get-url origin))
LD_FLAGS      ?= "-X="${GH_REPO}/${BIN_NAME}/cmd.appVersion=${VERSION}
REGISTRY      ?= ghcr.io/gray380
GH_REPO       ?= "github.com/gray380/${BIN_NAME}"
GOOS          ?= ${HOST_GOOS}
GOARCH        ?= ${HOST_GOARCH}
IMAGE_TAG     ?= ${REGISTRY}/${BIN_NAME}:${VERSION}
IMAGE_TAG_EXT ?= ${GOOS}-${GOARCH}

.PHONY: format lint test get build image push clean \
		linux-amd64 linux-arm64 \
		macos-amd64 macos-arm64 \
		windows-amd64 windows-arm64

format:
	gofmt -s -w ./

lint:
	go vet ./...

test:
	go test -v

get:
	go get

build: format get
	@echo "Building binary for ${GOOS}/${GOARCH} with version ${VERSION}..."
	CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build \
		-v \
		-o ${BIN_NAME} \
		-ldflags "-X="github.com/gray380/kbot/cmd.appVersion=${VERSION}

image:
	@echo "Building image for host platform ($(IMAGE_TAG)-$(IMAGE_TAG)) and running tests..."
	docker build \
	--build-arg HOST_GOOS=${HOST_GOOS} \
	--build-arg HOST_GOARCH=${HOST_GOARCH} \
	--build-arg RUN_TESTS=true \
	--build-arg VERSION=${VERSION} \
	-t ${IMAGE_TAG}-${IMAGE_TAG_EXT} .

push:
	@echo "Pushing image for host platform ($(IMAGE_TAG)-$(IMAGE_TAG))..."
	docker push ${IMAGE_TAG}-${IMAGE_TAG_EXT}

clean:
	@echo "Removing binary: ${BIN_NAME} and image: $(IMAGE_TAG)"
	rm -f ${BIN_NAME}
	@imgs="$$(docker image ls --format '{{.Repository}}:{{.Tag}}' --filter 'reference=$(IMAGE_TAG)*')"; \
	if [ -n "$$imgs" ]; then echo "$$imgs" | xargs -n1 docker rmi; \
	else echo "No images match $(IMAGE_TAG)*"; fi

linux-amd64:
	@echo "Building image with linux/amd64 binary (version: $(VERSION))..."
	docker build \
		--build-arg TARGETOS=linux \
		--build-arg TARGETARCH=amd64 \
		--build-arg VERSION=$(VERSION) \
		-t ${IMAGE_TAG}-linux-amd64 .

linux-arm64:
	@echo "Building image with linux/arm64 binary (version: $(VERSION))..."
	docker build \
		--build-arg TARGETOS=linux \
		--build-arg TARGETARCH=arm64 \
		--build-arg VERSION=$(VERSION) \
		-t ${IMAGE_TAG}-linux-arm64 .

macos-amd64:
	@echo "Building image with darwin/amd64 (macOS Intel) binary (version: $(VERSION))..."
	docker build \
		--build-arg TARGETOS=darwin \
		--build-arg TARGETARCH=amd64 \
		--build-arg VERSION=$(VERSION) \
		-t ${IMAGE_TAG}-macos-amd64 .

macos-arm64:
	@echo "Building image with darwin/arm64 (macOS Apple Silicon) binary (version: $(VERSION))..."
	docker build \
		--build-arg TARGETOS=darwin \
		--build-arg TARGETARCH=arm64 \
		--build-arg VERSION=$(VERSION) \
		-t ${IMAGE_TAG}-macos-arm64 .

windows-amd64:
	@echo "Building image with windows/amd64 binary (version: $(VERSION))..."
	docker build \
		--build-arg TARGETOS=windows \
		--build-arg TARGETARCH=amd64 \
		--build-arg VERSION=$(VERSION) \
		-t ${IMAGE_TAG}-windows-amd64 .

windows-arm64:
	@echo "Building image with windows/arm64 binary (version: $(VERSION))..."
	docker build \
		--build-arg TARGETOS=windows \
		--build-arg TARGETARCH=arm64 \
		--build-arg VERSION=$(VERSION) \
		-t ${IMAGE_TAG}-windows-arm64 .