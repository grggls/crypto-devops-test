# Write a Dockerfile to run Cosmos Gaia v7.1.0 (https://github.com/cosmos/gaia) 
# in a container. It should download the source code, build it and run without 
# any modifiers (i.e. docker run somerepo/gaia:v7.1.0 should run the daemon) as 
# well as print its output to the console. The build should be security conscious
# (and ideally pass a container image security test such as Anchor)

# Use a multi-stage docker build:
#  - stage 1: create a docker image that can download the Gaia repo
#  - stage 2: copy Gaia's own Dockerfile to build the daemon
#  - stage 3: copy the daemon into a distroless container and run it there

# Use Ubuntu latest per Gaia installation docs
# https://github.com/cosmos/gaia/blob/main/docs/getting-started/installation.md

# STAGE.1
FROM ubuntu:jammy AS gaia-downloader
WORKDIR /src/

# Install dev tools
RUN apt-get update && apt-get install -y git 
RUN git clone -b v7.1.0 https://github.com/cosmos/gaia.git

# STAGE.2
FROM golang:1.18-alpine AS gaiad-builder

# Grab the cloned repo from STAGE.1
COPY --from=gaia-downloader /src/gaia/ /src/gaia/

## Copied with a slight modifications from Gaia's Dockerfile
WORKDIR /src/gaia/
RUN go mod download
ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3
RUN apk add --no-cache $PACKAGES
RUN CGO_ENABLED=0 make install

## STAGE.3
## Add to a distroless container
FROM distroless.dev/static:latest
COPY --from=gaiad-builder /go/bin/gaiad /usr/local/bin/
EXPOSE 26656 26657 1317 9090
USER 0

ENTRYPOINT ["gaiad", "start"]
