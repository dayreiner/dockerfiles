FROM centos:latest
MAINTAINER dayreiner

ENV REDIS_URL=https://github.com/antirez/redis.git \
    REDIS_VERSION=3.2 \
    GOSU_URL=https://github.com/tianon/gosu/releases/download \
    GOSU_VERSION=1.10

# Add redis user and group
RUN groupadd -r redis && useradd -r -g redis redis

RUN yum clean all && yum makecache fast && yum -y update \
    && yum -y install ruby \
    && yum clean all && yum history new \
    && yum -y install git gcc make glibc-devel git

# Setup gosu for easier command execution
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "${GOSU_URL}/${GOSU_VERSION}/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "${GOSU_URL}/${GOSU_VERSION}/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

# Build Redis
RUN set -x \
    && mkdir -p /usr/src/redis \
    && git clone -b ${REDIS_VERSION} "$REDIS_URL" /usr/src/redis \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && cp /usr/src/redis/src/redis-trib.rb /usr/local/bin/redis-trib.rb \
    && chmod u+x /usr/local/bin/redis-trib.rb \
    && rm -rf /usr/src/redis \
    && yum -y history undo 1 && yum clean all \
    && mkdir /data && chown redis:redis /data

VOLUME /data
WORKDIR /data

COPY redis.conf /usr/local/etc/redis/redis.conf

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 6379 16379
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
