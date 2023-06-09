FROM alpine:latest
LABEL org.opencontainers.image.source https://github.com/joshhighet/torsocc
RUN apk update
RUN apk upgrade
RUN apk add tor
RUN echo 'SocksPort 0.0.0.0:9050' >> /etc/tor/torrc
RUN chown -R tor /etc/tor
USER tor
ENTRYPOINT ["tor"]
CMD ["-f", "/etc/tor/torrc"]
