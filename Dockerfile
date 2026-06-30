# TODO: base image + build for zigbee2mqtt. Mirror jellyfin/Dockerfile conventions.
FROM debian:12-slim
LABEL org.opencontainers.image.source="https://github.com/argyle-labs/zigbee2mqtt"
EXPOSE 8080
