FROM openresty/openresty:trusty

RUN mkdir -p /var/cache/nginx/proxy_cache

RUN echo "deb http://us.archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update && \
      apt-get install -y curl vim-tiny wget --no-install-recommends && \
      apt-get install -y libuuid1 --no-install-recommends && \
      apt-get install -y libnettle4 --no-install-recommends && \
      apt-get install -y ca-certificates && \
      apt-get clean && \
      rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

ENV PATH $PATH:/usr/local/openresty/nginx/sbin

RUN wget http://xrl.us/cpanm
RUN perl cpanm --notest Test::Nginx

VOLUME /code
WORKDIR /code

ENTRYPOINT []
