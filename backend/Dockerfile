# Stage 1: Build
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Copy dependency files first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o skillpulse .

# Stage 2: Run — use scratch for minimal image
FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/skillpulse /skillpulse

EXPOSE 8080

ENTRYPOINT ["/skillpulse"]
