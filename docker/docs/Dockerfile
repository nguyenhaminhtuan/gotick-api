FROM redocly/cli:2.39.0 AS bundle
WORKDIR /spec
COPY redocly.yaml ./
COPY api ./api
RUN redocly bundle

FROM scalarapi/api-reference:0.5.58 AS prod
COPY --from=bundle --chown=caddy:caddy /spec/api/dist/openapi.yaml /docs/openapi.yaml
EXPOSE 8080
