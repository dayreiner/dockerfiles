FROM centos:latest
MAINTAINER dayreiner

# Update and install latest packages and prerequisites
RUN yum -y update && yum clean all && yum install httpd
RUN yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm && yum clean all
RUN yum -y install git composer php56w php56w-cli php56w-common php56w-opcache php56w-mysql php56w-mbstring

COPY config/php.ini /etc/php.ini

# Setup SSH for checking out code from github
RUN echo "Setting up SSH for GitHub Checkouts..." && \
    mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
    touch /root/.ssh/known_hosts && \
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts && \
    chmod 600 /root/.ssh/known_hosts

EXPOSE 22 80
ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["-DFOREGROUND"]
