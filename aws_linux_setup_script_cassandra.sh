#!/bin/bash
# Title:				Amazon Linux Cassandra setup script
# Description:			sets up a new ec2 instance with cassandra
# Author:				Nick Batts
# Last Updated:			January 9, 2018


# log output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# set timezone
echo -e "ZONE=America/Denver\UTC=false" | tee /etc/sysconfig/clock
# create symbolic link between local time and time zone file
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime

echo "[cassandra]
name=Apache Cassandra
baseurl=https://www.apache.org/dist/cassandra/redhat/311x/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.apache.org/dist/cassandra/KEYS" | tee -a /etc/yum.repos.d/cassandra.repo

yum update -y
yum remove -y java
yum install -y java-1.8.0-openjdk cassandra

java -version

rm -rf /var/lib/cassandra/data/system/*

INSTANCE_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

sed -i "s/cluster_name: 'Test Cluster'/cluster_name: 'batts_cassandra_cluster'/g" /etc/cassandra/conf/cassandra.yaml
# can't reference self IPs from user-data scripts
# sed -i "s/- seeds: \"127.0.0.1\"/- seeds: \"$INSTANCE_IP\"/g" /etc/cassandra/conf/cassandra.yaml
sed -i "s/listen_address: localhost/listen_address:/g" /etc/cassandra/conf/cassandra.yaml
sed -i "s/start_rpc: false/start_rpc: true/g" /etc/cassandra/conf/cassandra.yaml
sed -i "s/rpc_address: localhost/rpc_address: 0.0.0.0/g" /etc/cassandra/conf/cassandra.yaml
sed -i "s/# broadcast_rpc_address: 1.2.3.4/broadcast_rpc_address: $INSTANCE_IP/g" /etc/cassandra/conf/cassandra.yaml
sed -i "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: Ec2Snitch/g" /etc/cassandra/conf/cassandra.yaml

sed -i "s/Djava.rmi.server.hostname=<public name>/Djava.rmi.server.hostname=$INSTANCE_IP/g" /etc/cassandra/conf/cassandra-env.sh

chkconfig cassandra on 			# start cassandra automatically on boot
service cassandra start			# cassandra does not start automatically

reboot