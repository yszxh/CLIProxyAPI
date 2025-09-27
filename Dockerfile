FROM golang:1.24-alpine AS builder
LABEL "language"="go"

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o ./CLIProxyAPI ./cmd/server/

FROM alpine:3.22.0

RUN apk add --no-cache tzdata ca-certificates

RUN mkdir -p /CLIProxyAPI

COPY --from=builder ./app/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI

WORKDIR /CLIProxyAPI

# Create custom config.yaml with your settings
RUN cat > /CLIProxyAPI/config.yaml << 'EOF'
# Server port
port: 8317

# Management API settings
remote-management:
  # Whether to allow remote (non-localhost) management access.
  allow-remote: true
  # Management key. If a plaintext value is provided here, it will be hashed on startup.
  secret-key: "Yszxh820515!"

# Authentication directory (supports ~ for home directory)
auth-dir: "/root/.cli-proxy-api"

# Enable debug logging
debug: false

# Number of times to retry a request
request-retry: 3

# Quota exceeded behavior
quota-exceeded:
  switch-project: true
  switch-preview-model: true

# API keys for authentication
api-keys:
  - "sk-820515"

# API keys for official Generative Language API
generative-language-api-key:
  - "AIzaSyDycCg0hYxfJ0PPxWwYdhwKawfhiRr1jdY"
  - "AIzaSyB6XRvsCYdmwGurQHYgBTP_XGbv-H1ovPc"
  - "AIzaSyBTlpxd1i4Rf7v9lgnZhkVuAS0bKmeSyi4"
  - "AIzaSyC2jCkzjNX_WNC5nWSCBq29cMDs6cDCnEo"
  - "AIzaSyBKkmA0unBC7N7RsX-eX3szVy6cmm-poLI"

# OpenAI compatibility providers
openai-compatibility:
  - name: "iflow"
    base-url: "https://apis.iflow.cn/v1"
    api-keys:
      - "sk-8320e756312bd852b2c99764372313d0"
      - "sk-b7158c3096ab9e26042834a215b4880f"
      - "sk-bcc1fc26a70d2a768b32942002bef4f7"
    models:
      - name: "kimi-k2-0905"
        alias: "kimi-k2"
  - name: "openrouter"
    base-url: "https://openrouter.ai/api/v1"
    api-keys:
      - "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"
      - "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"
      - "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"
      - "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"
    models:
      - name: "x-ai/grok-4-fast:free"
        alias: "grok-4-fast"

# Gemini Web settings
gemini-web:
  context: true
  max-chars-per-request: 1000000
  disable-continuation-hint: false
  code-mode: false

logging-to-file: false
usage-statistics-enabled: true
proxy-url: ""

auth:
  providers:
    - name: config-inline
      type: config-api-key
      api-keys:
        - sk-820515

request-log: false
EOF

EXPOSE 8317

ENV TZ=Asia/Shanghai

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

# Create auth directory
RUN mkdir -p /root/.cli-proxy-api

CMD ["./CLIProxyAPI"]