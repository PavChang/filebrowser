FROM alpine:latest
RUN apk update
RUN apk add ca-certificates \
                     mailcap \
                     curl \
                     jq
 
RUN apk add make cmake bash ncurses nodejs npm go git

RUN mkdir -p /build

ADD . /build/
WORKDIR /build/GmSSL-master
RUN mkdir -p build
WORKDIR /build/GmSSL-master/build
RUN cmake ..
RUN make && make test && make install
RUN ln -s /usr/local/lib/libgmssl.so.3 /usr/lib/libgmssl.so.3

WORKDIR /build
RUN make build
RUN cp filebrowser /filebrowser


COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh  # Make the script executable

HEALTHCHECK --start-period=2s --interval=5s --timeout=3s \
    CMD /healthcheck.sh || exit 1

VOLUME /srv
EXPOSE 443

COPY docker_config.json /.filebrowser.json

ENTRYPOINT [ "/filebrowser", "-a", "0.0.0.0", "-p", "443", "-k", "server.key", "-t", "server.pem", "-r", "/srv", "-d", "/database.db" ]
