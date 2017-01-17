FROM centos:latest
MAINTAINER dayreiner

ENV REDIS_URL=https://github.com/antirez/redis.git \
    REDIS_VERSION=3.2 \
    GOSU_URL=https://github.com/tianon/gosu/releases/download \
    GOSU_VERSION=1.10

# Updates and Install build requirements
RUN yum clean all && yum makecache fast && yum -y update \
    # Instal Ruby
    && yum -y install ruby \
    # Reset yum history so we can rollback the devtools installs / reduce image size
    && yum clean all && yum history new \
    && yum -y install git gcc make glibc-devel git

# Build Redis
RUN groupadd -r redis && useradd -r -g redis redis \
    && mkdir -p /usr/src/redis \
    && git clone -b ${REDIS_VERSION} "$REDIS_URL" /usr/src/redis \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    # Add redis-trib for future use, assuming it can work from a container
    && cp /usr/src/redis/src/redis-trib.rb /usr/local/bin/redis-trib.rb \
    && chmod +x /usr/local/bin/redis-trib.rb \
    && rm -rf /usr/src/redis \
    && yum -y history undo 1 && yum clean all \
    && mkdir /data && chown redis:redis /data \
    && gem install redis

# Add gosu
RUN gpg --keyserver na.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "${GOSU_URL}/${GOSU_VERSION}/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "${GOSU_URL}/${GOSU_VERSION}/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -rf /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

VOLUME /data
WORKDIR /data

COPY redis.conf /usr/local/etc/redis.conf

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 6379 16379
CMD [ "redis-server", "/usr/local/etc/redis.conf" ]
