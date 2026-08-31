FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
RUN git clone https://github.com/ar51an/unbound-exporter.git /src
WORKDIR /src
RUN go build -mod=mod -o /unbound_exporter .

FROM alpine:3.20
COPY --from=builder /unbound_exporter /usr/local/bin/unbound_exporter
ENTRYPOINT ["/usr/local/bin/unbound_exporter"]
