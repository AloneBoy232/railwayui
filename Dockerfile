FROM golang:1.22-alpine AS builder
RUN apk add --no-cache gcc musl-dev
WORKDIR /app
COPY . .
RUN go build -tags "nodaemon" -o vpn-ui main.go

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip /tmp/xray.zip -d /usr/local/bin/ && rm /tmp/xray.zip && chmod +x /usr/local/bin/xray
WORKDIR /app
COPY --from=builder /app/vpn-ui /app/vpn-ui
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh /app/vpn-ui
RUN mkdir -p /etc/x-ui /var/log/nginx
EXPOSE 8080
CMD ["/app/start.sh"]
