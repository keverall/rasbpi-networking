ARG TARGETARCH=arm64
FROM --platform=linux/${TARGETARCH} pihole/pihole:latest

LABEL maintainer="You <you@example.com>"
ARG BUILD_DATE
ARG VCS_REF
ENV DEBIAN_FRONTEND=noninteractive

# Metadata
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF

# Lightweight healthcheck suitable for Raspberry Pi 5 (aarch64)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nc -z -w3 127.0.0.1 53 || exit 1

# The official pihole/pihole image already provides the services and
# entrypoint. This Dockerfile forces an aarch64 base and adds build-time
# metadata so you can build a locally optimized image for Raspberry Pi 5.

