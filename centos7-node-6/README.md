# centos7-node-6

Centos 7 image with nodejs 6.x installed. Uses /app for serving a node app. Can either mount /app as a volume when running or use a child dockerfile to copy files to /app or override the WORKDIR.

Includes github ssh host certificate pre-installed. As an alternate deployment, you can create a child dockerfile that will clone your repository in to /app and then perform any actions you require afterwards via RUN statements.

For Dockerhub automated build - https://hub.docker.com/r/dayreiner/centos7-node-6/
