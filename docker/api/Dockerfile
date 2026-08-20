FROM golang:1.26-bookworm AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
COPY . .
# grant-staff rides along in this image rather than one of its own: it shares
# every dependency with the API, and a fourth image would need its own build,
# push and deploy path for a binary that runs by hand a handful of times.
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux \
    go build -trimpath -ldflags="-s -w" -o /out/ ./cmd/api ./cmd/grant-staff

FROM gcr.io/distroless/static-debian12:nonroot AS prod
COPY --from=build /out/api /api
COPY --from=build /out/grant-staff /grant-staff
ENTRYPOINT ["/api"]
