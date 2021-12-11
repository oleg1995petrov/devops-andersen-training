FROM golang:alpine as go-builder
WORKDIR /build
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o app .

FROM scratch
EXPOSE 8080
COPY --from=go-builder /build/app /app
CMD ["/app"]  
