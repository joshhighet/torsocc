FROM alpine:3.22 AS builder
LABEL org.opencontainers.image.source="https://github.com/joshhighet/torsocc"
RUN apk add --no-cache build-base git curl openssl-dev openssl-libs-static pkgconfig sqlite-dev sqlite-static musl-dev perl
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-cpu=native -C opt-level=z -C panic=abort -C codegen-units=1"
ARG ARTI_VERSION=1.6.0
RUN git clone --depth 1 --branch arti-v${ARTI_VERSION} https://gitlab.torproject.org/tpo/core/arti.git /src/arti
WORKDIR /src/arti
RUN cargo fetch
RUN cargo build --release --bin arti --features=static
RUN strip /src/arti/target/release/arti

FROM alpine:3.22 AS runtime
RUN apk add --no-cache ca-certificates libgcc sqlite-libs && \
    adduser -D -s /bin/sh toruser
COPY --from=builder /src/arti/target/release/arti /usr/local/bin/arti
COPY config.toml /config/config.toml
RUN chown -R toruser:toruser /config
USER toruser
EXPOSE 9050 5353
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 CMD nc -z localhost 9050 || exit 1
ENTRYPOINT ["/usr/local/bin/arti", "proxy", "-c", "/config/config.toml"]