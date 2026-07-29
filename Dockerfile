# ==============================================================================
# Railway-optimized multi-stage build for vpn-ui
# ==============================================================================
FROM golang:1.26.5-bookworm AS deps
WORKDIR /build
ENV CGO_ENABLED=1
COPY go.mod go.sum ./
RUN go mod download

FROM deps AS builder
WORKDIR /build
COPY . .
RUN git submodule update --init --recursive
RUN mkdir -p /app \
    && (go build -tags "nodaemon" -ldflags="-s -w" -o /app/vpn-ui . || \
        go build -tags "nodaemon" -ldflags="-s -w" -o /app/vpn-ui main.go || \
        go build -tags "nodaemon" -ldflags="-s -w" -o /app/vpn-ui ./cmd/vpn-ui)
RUN /app/vpn-ui -v || true

# Final image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    nginx sqlite3 jq curl ca-certificates unzip dos2unix \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Xray-core (pre-downloaded for faster startup)
RUN curl -fsSL -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip -q /tmp/xray.zip -d /tmp/xray \
    && mv /tmp/xray/xray /usr/local/bin/xray-linux-amd64 \
    && ln -sf /usr/local/bin/xray-linux-amd64 /usr/local/bin/xray \
    && rm -rf /tmp/xray /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray-linux-amd64 \
    && xray-linux-amd64 -version || true

WORKDIR /app
COPY --from=builder /app/vpn-ui /app/vpn-ui

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
COPY auto_config_api.py /app/auto_config_api.py

RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template /app/auto_config_api.py 2>/dev/null || true \
    && chmod +x /app/start.sh /app/auto_config_api.py /app/vpn-ui \
    && mkdir -p /etc/x-ui /var/log/nginx /app/bin

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

STOPSIGNAL SIGTERM
CMD ["/app/start.sh"]
