FROM alpine:latest as build

WORKDIR /downloads
RUN apk add mercurial git

RUN hg clone https://hg.nginx.org/nginx/
RUN git clone https://github.com/vinnyA3/nginx-rtmp-module.git

# Done here so source code layers are cached before build deps
RUN apk add \
    make \
    musl-dev \
    gcc \
    pcre-dev \
    openssl-dev \
    zlib-dev

WORKDIR /downloads/nginx
RUN auto/configure \
    --add-module=/downloads/nginx-rtmp-module \
    --with-http_ssl_module \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx/nginx.pid \
    --lock-path=/var/lock/nginx/nginx.lock \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/tmp/nginx-client-body \
    --with-http_ssl_module \
    --with-threads

RUN sed -i 's/-Werror//g' objs/Makefile
RUN make -j$(nproc)

FROM alpine:latest

RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/run/nginx
RUN touch /var/run/nginx/nginx.pid
RUN apk add pcre openssl zlib

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /downloads/nginx/objs/nginx /

ENTRYPOINT ["/nginx", "-g", "daemon off;"]
