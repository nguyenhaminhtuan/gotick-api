FROM golang:1.26-bookworm AS build
ARG GOOSE_VERSION=v3.27.0
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux \
    go install github.com/pressly/goose/v3/cmd/goose@${GOOSE_VERSION}

FROM alpine:3.22 AS prod
COPY --from=build /go/bin/goose /usr/local/bin/goose
COPY db/migrations /db/migrations
COPY db/background /db/background
COPY docker/migrate/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && adduser -D -u 65532 nonroot
USER nonroot
ENTRYPOINT ["/entrypoint.sh"]
CMD ["up"]
