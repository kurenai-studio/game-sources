# Docker configuration for Space Shooter

FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN go build -ldflags="-s -w" -o space-shooter cmd/game/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/space-shooter .
COPY --from=builder /app/configs ./configs

EXPOSE 8080

CMD ["./space-shooter"]
