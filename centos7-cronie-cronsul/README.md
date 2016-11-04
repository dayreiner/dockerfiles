CentOS 7, Cronie, Cronsul Cluster
===================

This image will launch a clustered cron container using [cronie](https://fedorahosted.org/cronie/). Cron jobs can be scheduled standalone or the cron can be deployed to multiple instances using [cronsul](https://github.com/EvanKrall/cronsul) to ensure jobs only run on a single instance. A [Consul](https://hub.docker.com/_/consul/) key-value store is required in order to use cronsul for distributed jobs. 

The container includes the docker client in order to run `docker exec` to execute scheduled jobs on other containers.

----------

Job Configuration
-------------
Define your cron jobs in a file such as below. This file will be mounted as a volume when running the container. The container will pull the contents of your file and import it in to the crontab on startup. 

For standalone jobs, use standard cron format:

```
CRONLOG=/dev/stdout
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH
* * * * * echo "Hello World!"
```
To define distributed jobs that can run on any cron container (but not on more than one container simultaneously), use cronsul to get a lock and schedule each job. Simply add `cronsul $jobname` in front of your regular commands. You must also define `$CONSUL_HOST` and `$CONSUL_PORT` to point to your consul instance to manage locking -- this can be done in the crontab or passed to the container via environment variables in your `docker run` command:

```
SHELL=/bin/bash
HOME=/
CRONLOG=/dev/stdout
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH
CONSUL_HOST=my-consul-server.example.com
CONSUL_PORT=8500
* * * * * cronsul cronlocktest echo "Hello! Container $(hostname) obtained the lock in consul."
```

Run the Container
-------------
To run the container with docker support (optional), make sure to mount docker.sock as a volume in the container. You must also pass it the path to your cron jobs file as defined in the previous section (required):

```
docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v $/path/to/your/cron-jobs-file:/cron-jobs --name=cronsul dayreiner/cronie-cronsul
```
or via docker-compose:

```
  cron:
    image: dayreiner/cronie-cronsul:latest
    container_name: cron
    network_mode: host
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "/opt/cron/cron-jobs:/cron-jobs"
```
