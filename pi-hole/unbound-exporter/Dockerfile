FROM golang:1.25-alpine AS builder
RUN apk add --no-cache git
RUN git clone https://github.com/letsencrypt/unbound_exporter.git /src
WORKDIR /src
RUN go build -o /unbound_exporter .

FROM alpine:3.19
COPY --from=builder /unbound_exporter /usr/local/bin/unbound_exporter
ENTRYPOINT ["/usr/local/bin/unbound_exporter"]


