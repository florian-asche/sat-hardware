### Build stage: resolve locked dependencies into a venv (spidev/evdev need a compiler)
FROM python:3.13-slim-trixie AS build

ARG VERSION=0.0.0.dev0
ENV DEBIAN_FRONTEND=noninteractive \
    SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION} \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && \
    apt-get install --yes --no-install-recommends build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN python -m venv /opt/uv && /opt/uv/bin/pip install --no-cache-dir uv==0.9.5

COPY pyproject.toml uv.lock README.md LICENSE ./
COPY src/ ./src/

# Install exactly the locked third-party dependencies first (hash-checked),
# then the project itself without re-resolving anything.
RUN python -m venv .venv && \
    /opt/uv/bin/uv export --locked --extra daemon --no-emit-project --format requirements-txt \
        --output-file /tmp/requirements.txt && \
    .venv/bin/pip install --no-cache-dir --require-hashes -r /tmp/requirements.txt && \
    .venv/bin/pip install --no-cache-dir --no-deps . && \
    .venv/bin/pip uninstall --yes pip setuptools wheel && \
    find .venv -name '__pycache__' -prune -exec rm -rf {} +

### Runtime stage
FROM python:3.13-slim-trixie

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# The GPL requires the corresponding source to be available: see the source label.
LABEL \
    org.opencontainers.image.title="SAT-Hardware-Agent" \
    org.opencontainers.image.description="Hardware agent for voice-assistant satellites (LEDs, buttons, sensors)" \
    org.opencontainers.image.licenses="GPL-3.0-only" \
    org.opencontainers.image.source="https://github.com/florian-asche/sat-hardware" \
    org.opencontainers.image.documentation="https://github.com/florian-asche/sat-hardware/blob/main/docs/docker.md" \
    org.opencontainers.image.url="https://github.com/florian-asche/sat-hardware"

### Runtime packages:
# - libgpiod3:       GPIO access (python gpiod bindings)
# - flashrom:        XMOS firmware flashing (sat1-xmos, xmos.flash_firmware)
# - ca-certificates: TLS connections to the MQTT broker
RUN apt-get update && \
    apt-get install --yes --no-install-recommends libgpiod3 flashrom ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale

# Non-root user. Device access comes from supplementary groups (see docker-compose.yml).
# UID/GID 1000 matches the default user of Raspberry Pi OS, so a bind-mounted ./config is writable.
RUN groupadd --gid 1000 satellite1 && \
    useradd --uid 1000 --no-create-home --gid satellite1 satellite1d && \
    install -d -o satellite1d -g satellite1 -m 0750 /config /run/satellite1 /var/lib/satellite1 /etc/satellite1

WORKDIR /app
COPY --from=build /app/.venv ./.venv
COPY etc/satellite1.conf /app/default-satellite1.conf
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

ENV PATH="/app/.venv/bin:${PATH}" \
    CONFIG_FILE=/config/satellite1.conf

VOLUME ["/config", "/var/lib/satellite1"]
USER satellite1d

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD ["python", "-c", "import socket,sys; s=socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect('/run/satellite1/satellite1d.sock')"]

ENTRYPOINT ["./docker-entrypoint.sh"]
