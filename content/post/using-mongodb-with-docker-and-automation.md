+++
title = "Using MongoDB with Docker and Automation"
subtitle = "A mature database community in KL"
author = "Matias Cascallares"
date = "2015-04-20T14:12:26+08:00"
categories = ["MongoDB", "Docker"]
description = "Lately I have been playing a lot with Docker. I like the whole idea of containers, how you can easily deploy processes in an isolated environment with low resource overhead. In addition, I think another big win introduced by Docker is the image concept: a hermetically sealed portable file that contains all that you need to run your process or application: binaries, dependencies and configuration. Just beautiful!"
draft = true
keywords = ["software", "mongodb", "docker", "databases"]
totop = true
socialsharing = true
authortwitter = "http://twitter.com/mcascallares"
+++

Lately I have been playing a lot with Docker. I love the whole idea of containers, how you can easily deploy processes in an *isolated* environment with low resource overhead. In addition, I think another big win introduced by Docker is the [image concept](http://docs.docker.com/userguide/dockerimages/): a hermetically sealed portable file that contains all that you need to run your process or application: binaries, dependencies and configuration. Just beautiful!

Working at MongoDB means I need to run several mongod processes every day: to test a specific feature, to demo something, configuration example, etc. It also means that sometimes I need to deploy multiple nodes with different configurations to simulate a real scenario. I started to use Docker for this and it has been working like a breeze. In a couple of seconds I can start multiple mongod processes with different configurations, different Linux distributions and play around with them. Before starting with Docker I used [Vagrant](https://www.vagrantup.com) instances with VirtualBox, but it required more resources and it was slower.

The triangulation of my MongoDB sandbox environment is completed with [MMS Automation](https://mms.mongodb.com/). For those who don't know MMS, it is a cloud service to manage, monitor and backup your MongoDB instances that can be running everywhere: cloud, on-premise servers or your own laptop in a kind of *bring your own infrastructure* principle. One interesting aspect of MMS is that you do not need to worry about installing and managing your MongoDB instances, you just need to specify which machines do you want to deploy to and the desired MongoDB configuration (e.g. I want a 3-nodes replica set).

When I updated my sandbox environment to Docker I built an [image ready to work with MMS Automation](https://registry.hub.docker.com/u/mcascallares/mongodb-automation/) that includes the MMS Automation agent pre-installed. That means that if I want to start a new mongod process I just start one container with this image specifying my MMS GroupId + ApiKey and the container is ready to be provisioned using the MMS web interface.

If I need to deploy a distributed environment like a MongoDB replica set or sharded cluster I need to take care of the networking among my replica nodes: provide connectivity and host resolution among all of them. You can find [really good posts](http://progrium.com/blog/2014/08/20/consul-service-discovery-with-docker/) out there explaining how to achieve service discovery with Docker so I am not going into details on this. What I used for my sandbox was [Skydock](https://github.com/crosbymichael/skydock): a DNS container running Skydns that is going to listen for container events (start, stop, kill, etc.) and register/unregister DNS entries allowing hostname resolution across all my containers.

Putting all together to deploy a 3-nodes replica set using [Docker Compose](http://www.fig.sh):

```bash
# running a DNS container with Skydns
docker run -d \
    -p 172.17.42.1:53:53/udp \
    --name skydns crosbymichael/skydns \
    -nameserver 8.8.8.8:53 \
    -domain docker


# running Skydock container to hook docker events with DNS updates
docker run -d \
    -v /var/run/docker.sock:/docker.sock \
    --name skydock crosbymichael/skydock \
    -ttl 30 \
    -environment dev \
    -s /docker.sock \
    -domain docker \
    -name skydns


# running 3 mongod processes in 3 different containers, one agent per container.
docker run -d \
    --name mongod1 \
    -h mongod1.mongodb-automation.dev.docker \
    --dns 172.17.42.1 \
    -p 27017:27000 \
    mcascallares/mongodb-automation:latest \
    --mmsBaseUrl=https://mms.mongodb.com \
    --mmsGroupId=<your_mms_group_id> \
    --mmsApiKey=<your_mms_api_key>


docker run -d \
    --name mongod2 \
    -h mongod2.mongodb-automation.dev.docker \
    --dns 172.17.42.1 \
    -p 27018:27000 \
    mcascallares/mongodb-automation:latest \
    --mmsBaseUrl=https://mms.mongodb.com \
    --mmsGroupId=<your_group_id> \
    --mmsApiKey=<your_mms_api_key>


docker run -d \
    --name mongod3 \
    -h mongod3.mongodb-automation.dev.docker \
    --dns 172.17.42.1 \
    -p 27019:27000 \
    mcascallares/mongodb-automation:latest \
    --mmsBaseUrl=https://mms.mongodb.com \
    --mmsGroupId=<your_group_id> \
    --mmsApiKey=<your_mms_api_key>

```
<br>
Deploying this set of containers I can use the following containers:

- mongod1.mongodb-automation.dev.docker
- mongod2.mongodb-automation.dev.docker
- mongod3.mongodb-automation.dev.docker

to deploy my MongoDB replica set using MMS user interface. Check [MMS Documentation](https://docs.mms.mongodb.com).

Find more details and other setup examples at [Docker Hub](https://registry.hub.docker.com/u/mcascallares/mongodb-automation/).
