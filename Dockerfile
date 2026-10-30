### Runtime image: nothing but the Debian package.
# Build the package first (script/build-deb, CI job "build-deb"); it lands in dist/.
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

# Service user with a fixed UID/GID (matches the default Raspberry Pi OS user, so a bind-mounted
# ./config is writable). The package's postinst reuses an existing user and group.
RUN groupadd --gid 1000 satellite1 && \
    useradd --uid 1000 --no-create-home --gid satellite1 --shell /usr/sbin/nologin satellite1d

# apt resolves the package Depends; postinst builds /opt/satellite1/venv from the shipped wheelhouse.
# The package also ships the entrypoint, config template and udev rules.
COPY dist/*.deb /tmp/pkg/
RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates /tmp/pkg/*.deb && \
    rm -rf /tmp/pkg /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale && \
    install -d -o satellite1d -g satellite1 -m 0750 /config /run/satellite1 /var/lib/satellite1

VOLUME ["/config", "/var/lib/satellite1"]
USER satellite1d

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD ["/opt/satellite1/venv/bin/python", "-c", "import socket; s=socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect('/run/satellite1/satellite1d.sock')"]

ENTRYPOINT ["sat-hardware-agent-entrypoint"]
