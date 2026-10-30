### Stage 1: build the Debian package (same recipe as the Raspberry Pi install)
FROM debian:trixie AS deb

ENV DEBIAN_FRONTEND=noninteractive

# Build-Depends of debian/control plus what debian/rules needs to build the wheelhouse
# (spidev/evdev are compiled, hence build-essential and python3-dev).
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        build-essential debhelper dh-python devscripts fakeroot \
        python3-all python3-dev python3-venv python3-pip \
        python3-setuptools python3-setuptools-scm python3-wheel \
        ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# debian/rules builds from /project (PRJ_ROOT).
WORKDIR /project
COPY pyproject.toml uv.lock README.md LICENSE Makefile ./
COPY src/ ./src/
COPY etc/ ./etc/
COPY udev/ ./udev/
COPY debian/ ./debian/

RUN dpkg-buildpackage --build=any --no-sign && \
    mkdir /out && cp /*.deb /out/

### Optional stage: `docker build --target deb-export --output type=local,dest=out .`
FROM scratch AS deb-export
COPY --from=deb /out/ /

### Stage 2: runtime image that just installs the .deb
FROM debian:trixie-slim

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CONFIG_FILE=/config/satellite1.conf

# The GPL requires the corresponding source to be available: see the source label.
LABEL \
    org.opencontainers.image.title="SAT-Hardware-Agent" \
    org.opencontainers.image.description="Hardware agent for voice-assistant satellites (LEDs, buttons, sensors)" \
    org.opencontainers.image.licenses="GPL-3.0-only" \
    org.opencontainers.image.source="https://github.com/florian-asche/sat-hardware" \
    org.opencontainers.image.documentation="https://github.com/florian-asche/sat-hardware/blob/main/docs/docker.md" \
    org.opencontainers.image.url="https://github.com/florian-asche/sat-hardware"

# Create the service user with a fixed UID/GID first (matches the default Raspberry Pi OS user, so
# a bind-mounted ./config is writable). The package's postinst reuses existing user and group.
RUN groupadd --gid 1000 satellite1 && \
    useradd --uid 1000 --no-create-home --gid satellite1 --shell /usr/sbin/nologin satellite1d

# Install the package; apt resolves its Depends (python3-venv, flashrom, libgpiod3, ...).
# postinst builds /opt/satellite1/venv from the shipped wheelhouse and links the commands.
COPY --from=deb /out/*.deb /tmp/pkg/
RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates /tmp/pkg/*.deb && \
    rm -rf /tmp/pkg /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale && \
    install -d -o satellite1d -g satellite1 -m 0750 /config /run/satellite1 /var/lib/satellite1

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/config", "/var/lib/satellite1"]
USER satellite1d

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD ["/opt/satellite1/venv/bin/python", "-c", "import socket; s=socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect('/run/satellite1/satellite1d.sock')"]

ENTRYPOINT ["docker-entrypoint.sh"]
