#!/bin/bash

docker run \
  --name snips-server \
  -v /volume1/@docker/volumes/snips/_data/log/:/var/log \
  -v /volume1/@docker/volumes/snips/_data/snips.toml:/etc/snips.toml \
  -v /volume1/@docker/volumes/snips/_data/start-snips.cfg:/start-snips.cfg \
  -v /volume1/@docker/volumes/snips/_data/:/usr/share/snips \
  -v /volume1/@docker/volumes/snips/_data/skills:/var/lib/snips/skills \
  -e ENABLE_MQTT=no \
  -e ENABLE_HOTWORD_SERVICE=no \
  snips-server:latest
