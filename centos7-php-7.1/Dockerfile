FROM centos/httpd:latest
MAINTAINER dayreiner

# Update and install latest packages and prerequisites
RUN yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
RUN yum -y install git composer php71w php71w-cli php71w-common php71w-opcache php71w-mysql php71w-mbstring

COPY config/php.ini /etc/php.ini

# Setup SSH for checking out code from github
RUN echo "Setting up SSH for GitHub Checkouts..." && \
    mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
    touch /root/.ssh/known_hosts && \
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts && \
    chmod 600 /root/.ssh/known_hosts

EXPOSE 80
ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["-DFOREGROUND"]
