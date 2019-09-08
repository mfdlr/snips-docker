# Snips on Synology DSM (Docker)
Run [Snips](https://snips.ai/) platform on a Synology NAS and multiple satellites!

The motivation for this container is to run "Snips Voice Assistant" with a satellite configuration. The satellites may be distributed in your house as needed, they will listen to a hotword (e.g. "Hey Snips") and once detected stream the audio to this Docker server component. The server runs the actual assistant with the configured skills and streams back the audio to the satellite.
- see the official Guide from Snips: https://docs.snips.ai/articles/platform/satellites

This container provides only a server instance without any direct sound input / output. You will need a "satellite device" which contains microphone and speakers. My hardware setup is:
- Server Docker container runs on my Synology DS918+, which is a x86-based NAS.
- Satellites are based on Raspberry Pi Zero W

Note: you cannot run the server parts on a Raspberry Pi Zero W, you will need a Raspberry Pi 3B+/4 for that.


## Prepare Synology DSM (Snips server) ##

### (1) Build Docker image ###
- clone this repo on your local PC with `git clone`
- copy cloned folder to your NAS on any share, e.g. `software`
- SSH-login to your NAS and `cd` into the copied folder, e.g.
```
$ cd /volume1/software/snips-docker
```

- build the docker image, set your timezone and architecture as a build argument.
```
# Set your prefered image name, e.g. snips-server:latest
docker build \
  --build-arg BUILD_ARCH=amd64 \
  --build-arg TIMEZONE=Europe/Berlin \
  -f Dockerfile.dsm \
  -t snips-server:latest .
```

### (2) Prepare directories ###
- create a new Docker volume
```
$ docker volume create snips
```
- find the path of your mountpoint for the new volume
```
$ docker volume inspect snips
[
    {
        "CreatedAt": "2019-09-02T16:07:27+02:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/volume1/@docker/volumes/snips/_data",
        "Name": "snips",
        "Options": {},
        "Scope": "local"
    }
]
```
- create log and skills folder
```
$ mkdir /volume1/@docker/volumes/snips/_data/log
$ mkdir /volume1/@docker/volumes/snips/_data/skills
```
- configure the MQTT server settings in `snips.toml`
- copy config files to new volume
```
$ cp /volume1/software/snips-docker/snips.toml /volume1/@docker/volumes/snips/_data/
$ cp /volume1/software/snips-docker/start-snips.cfg /volume1/@docker/volumes/snips/_data/
```

### (3) Create and copy Assistant ###
- Create your assistant at https://console.snips.ai
- Download your assistant
- Unzip your new assistant on your local PC (because Synology NAS does not have `unzip` command), e.g.
```
$ cd downloads
$ unzip assistant_proj_Xr3k725M86V1
```
- copy extracted `assistant` folder on NAS via network share (or scp)
- move folder to your volume mountpoint
```
$ mv /volume1/software/snips-docker/assistant /volume1/@docker/volumes/snips/_data
```


### (4) Run container ###
- start the container
  - `<container name>` Choose a name for the container
  - `<log path>` <b>optionally</b>, path on docker host where the snips logs will be stored
  - `<path to snips.toml>` Path to your snips.toml file
  - `<path to start-snips.cfg>` Path to startup config file
  - `<path to snips assistant>` Path to your assistant
  - `<path to snips skills>` Path where skills are installed to
  - `<image-name>` Name of the docker image that you have create with docker build
  - `ENABLE_MQTT=<yes/no>`
    - `yes (or not set)` = start a mqtt server inside the container.
    - `no` = you have to set up a separate mqtt server in snips.toml
  - `ENABLE_HOTWORD_SERVICE=<yes/no>`
    - `yes (or not set)` = start the hotword recognition service (if you want to have a microphone on your NAS).
    - `no` = no hotword recognition (makes sense for satellite configuration)

```
docker run --name <container name> \
  -v <log path>/:/var/log:Z \
  -v <path to snips.toml>:/etc/snips.toml \
  -v <path to start-snips.cfg>:/start-snips.cfg \
  -v <path to snips assistant>:/usr/share/snips \
  -v <path to snips skills>:/var/lib/snips/skills \
  -e ENABLE_MQTT=<yes/no> \
  -e ENABLE_HOTWORD_SERVICE=<yes/no> \
  -p 1883:1883 \
  <image-name>
```

Example for Synology DSM 918+ with external MQTT server (configured in snips.toml)

```
docker run \
  --name snips-server:latest \
  -v /volume1/@docker/volumes/snips/_data/log/:/var/log \
  -v /volume1/@docker/volumes/snips/_data/snips.toml:/etc/snips.toml
  -v /volume1/@docker/volumes/snips/_data/start-snips.cfg:/start-snips.cfg
  -v /volume1/@docker/volumes/snips/_data/:/usr/share/snips \
  -v /volume1/@docker/volumes/snips/_data/skills:/var/lib/snips/skills \
  -e ENABLE_MQTT=no \
  -e ENABLE_HOTWORD_SERVICE=no \
  snips-server
```

### (5) Container / skill configuration ###
After the first container startup your configured skills are cloned and installed, you may set individual skill settings in `/volume1/@docker/volumes/snips/_data/skills/` subdirectories and `config.ini` files.

To stop reinstalling every skill on container startup deactivate this in `/volume1/@docker/volumes/snips/start-snips.cfg`

```
# enable internal mqtt server
ENABLE_MQTT=no
# enable local hotword detector
ENABLE_HOTWORD_SERVICE=no

# setting to "yes" will delete old skills and git clone and setup new ones
# setting to "no" will reuse the existing installed skills
INSTALL_SKILLS=yes
```

## Prepare Snips satellite(s) ##
I am using the following hardware for a satellite
- Raspberry Pi Zero W
- ReSpeaker 2-Mic HAT

Just follow the official guide for installation, nothing special to setup here:
https://docs.snips.ai/articles/platform/satellites#step-1-installation-of-the-snips-satellite-package

Adjust the MQTT server settings when needed, use the `snips.toml-satellite` file as an example.

## Credits ##
- based on David Bilay work, https://github.com/dYalib/snips-docker
- based on Home Assistant docker base image


## TODO ##
- [X] Find out why --build-arg does not work on Synology
  - see this workaround: https://gist.github.com/agross/614b3c85dcc152e258403f4c5d4273b7
- [ ] Add / test for non-x86 platforms (ARM-based)
