#@# vim: set filetype=dockerfile:
FROM alpine:3.16.1
LABEL maintainer "Takahiro INOUE <github.com/hinata>, Agile Digital <hello@agiledigital.com.au>"

ENV NGINX_VERSION 1.23.1

WORKDIR /tmp

RUN apk update && \
  apk add       \
  alpine-sdk  \
  openssl-dev \
  pcre-dev    \
  zlib-dev

RUN addgroup -g 101 -S nginx
RUN adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

RUN curl -LSs http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O                                             && \
  tar xf nginx-${NGINX_VERSION}.tar.gz                                                                             && \
  cd     nginx-${NGINX_VERSION}                                                                                    && \
  git clone https://github.com/chobits/ngx_http_proxy_connect_module                                               && \
  patch -p1 < ./ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch                             && \
  ./configure                                                                                                         \
  --add-module=./ngx_http_proxy_connect_module                                                                      \
  --sbin-path=/usr/sbin/nginx                                                                                       \
  --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' && \
  make -j $(nproc)                                                                                                 && \
  make install                                                                                                     && \
  rm -rf /tmp/*

RUN mkdir -p /var/log/nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

WORKDIR /

STOPSIGNAL SIGTERM

CMD [ "nginx", "-g", "daemon off;" ]
