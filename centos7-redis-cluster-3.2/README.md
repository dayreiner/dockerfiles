# CentOS 7, Redis 3.2 Cluster

Launch a multi-node Redis 3.2 cluster using docker. Requires the redis-trib.rb script (linked below) to manage the cluster.

Note that redis cluster does not play nicely with the bridge interface and port forwarding. Host-based networking works fine, overlay probably too.

## Prerequisites

- [redis-trib.rb](https://github.com/antirez/redis/blob/3.2/src/redis-trib.rb)
- A copy of the script is also present on the container in /usr/local/bin

## Start the Cluster Instances

Launch three redis instances using host networking across three instances on $host1 $host2 and $host3

```shell
docker run --network=host -d --name redis dayreiner/centos7-redis-cluster:latest
```

## Create The Cluster

On one of the dockerhosts, you'll need to run redis-trib.rb to initialize the cluster across the deployed containers. 

```shell
docker cp redis:/usr/local/bin/redis-trib.rb ./redis-trib.rb
chmod +x redis-trib.rb
./redis-trib.rb create --replicas 0 $host1:6379 $host2:6379 $host3:6379
```

This will run through the cluster initialization process on the three containers. Make sure to respond "yes" when prompted:

```
>>> Creating cluster
Connecting to node $host1:6379: OK
Connecting to node $host2:6379: OK
Connecting to node $host3:6379: OK
>>> Performing hash slots allocation on 3 nodes...
Using 3 masters:
$host1:6379
$host2:6379
$host3:6379
M: 344a19e87033ef62d5e8d31807156072e76221af $host1:6379
   slots:0-5460 (5461 slots) master
M: 750c0fbe10c8eac1e7d89fdac8a8ff9826b78dbb $host2:6379
   slots:5461-10922 (5462 slots) master
M: 4a17048efc59575749bcdb773a0316fa3c742444 $host3:6379
   slots:10923-16383 (5461 slots) master
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join.
>>> Performing Cluster Check (using node $host1:6379)
M: 344a19e87033ef62d5e8d31807156072e76221af $host1:6379
   slots:0-5460 (5461 slots) master
M: 750c0fbe10c8eac1e7d89fdac8a8ff9826b78dbb $host2:6379
   slots:5461-10922 (5462 slots) master
M: 4a17048efc59575749bcdb773a0316fa3c742444 $host3:6379
   slots:10923-16383 (5461 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.

```

## Confirm Cluster Operation

Once the cluster is operational, you can run redis-cli and use the "cluster info" and "cluster nodes" commands to see the status of the cluster and the individual nodes.

```shell
$ docker exec -ti redis bash -c "redis-cli cluster info"
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:3
cluster_size:3
cluster_current_epoch:3
cluster_my_epoch:2
cluster_stats_messages_sent:1483972
cluster_stats_messages_received:1483968

$ docker exec -ti redis bash -c "redis-cli cluster nodes"
750c0fbe10c8eac1e7d89fdac8a8ff9826b78dbb $host2:6379 master - 0 1425302527838 2 connected 5461-10922
4a17048efc59575749bcdb773a0316fa3c742444 $host3:6379 master - 0 1425302526819 3 connected 10923-16383
344a19e87033ef62d5e8d31807156072e76221af $host1:6379 myself,master - 0 0 1 connected 0-5460
```
