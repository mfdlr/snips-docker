#!/bin/bash
docker build \
  --build-arg BUILD_ARCH=amd64 \
  --build-arg TIMEZONE=Europe/Berlin \
  -f Dockerfile.dsm \
  -t snips-server:latest .
