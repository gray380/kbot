FROM quay.io/projectquay/golang:1.25 AS builder

ARG TARGETOS
ARG TARGETARCH

ARG HOST_GOOS
ARG HOST_GOARCH

ARG RUN_TESTS=false
ARG VERSION=unknown

ENV GOOS=${TARGETOS:-${HOST_GOOS}}
ENV GOARCH=${TARGETARCH:-${HOST_GOARCH}}

WORKDIR /go/src/app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN echo "--- Build Info ---" && \
    echo "Native platform: ${HOST_GOOS}/${HOST_GOARCH}" && \
    echo "Target platform: ${GOOS}/${GOARCH}" && \
    echo "Run tests flag:  ${RUN_TESTS}" && \
    echo "--------------------"

RUN if [ "${RUN_TESTS}" = "true" ]; then \
        if [ "${GOOS}" = "${HOST_GOOS}" ] && [ "${GOARCH}" = "${HOST_GOARCH}" ]; then \
            echo "Running tests for native platform ${GOOS}/${GOARCH}..."; \
            go test ./...; \
        else \
            echo "Skipping tests: RUN_TESTS=true but target platform ${GOOS}/${GOARCH} does not match native ${HOST_GOOS}/${HOST_GOARCH}"; \
        fi \
    else \
        echo "Skipping tests: RUN_TESTS=false"; \
    fi

RUN make build VERSION=${VERSION} GOOS=${GOOS} GOARCH=${GOARCH}

FROM scratch

WORKDIR /

COPY --from=builder /go/src/app/kbot .
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ENTRYPOINT ["./kbot"]
