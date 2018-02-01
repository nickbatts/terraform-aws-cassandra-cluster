#!/bin/bash
# Title:				Amazon Ubuntu Cassandra setup script
# Description:			sets up a new ec2 instance with cassandra
# Author:				Nick Batts
# Last Updated:			January 29, 2018


# log output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# set timezone
#echo -e "ZONE=America/Denver\UTC=false" | tee /etc/sysconfig/clock
# create symbolic link between local time and time zone file
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime

echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -

apt-get update && apt-get dist-upgrade -y
apt-get install -y default-jdk cassandra

java -version

rm -rf /var/lib/cassandra/data/system/*

INSTANCE_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

sed -i "s/cluster_name: 'Test Cluster'/cluster_name: 'batts_cassandra_cluster'/g" /etc/cassandra/cassandra.yaml
# can't reference other instances private IPs from user-data scripts
# sed -i "s/- seeds: \"127.0.0.1\"/- seeds: \"$INSTANCE_IP\"/g" /etc/cassandra/cassandra.yaml
sed -i "s/listen_address: localhost/listen_address:/g" /etc/cassandra/cassandra.yaml
sed -i "s/start_rpc: false/start_rpc: true/g" /etc/cassandra/cassandra.yaml
sed -i "s/rpc_address: localhost/rpc_address: 0.0.0.0/g" /etc/cassandra/cassandra.yaml
sed -i "s/# broadcast_rpc_address: 1.2.3.4/broadcast_rpc_address: $INSTANCE_IP/g" /etc/cassandra/cassandra.yaml
sed -i "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: Ec2Snitch/g" /etc/cassandra/cassandra.yaml

sed -i 's/# JVM_OPTS="$JVM_OPTS -Djava.rmi.server.hostname=<public name>/JVM_OPTS="$JVM_OPTS -Djava.rmi.server.hostname='$INSTANCE_IP'/g' /etc/cassandra/cassandra-env.sh

#chkconfig cassandra on 			# start cassandra automatically on boot
service cassandra start			# cassandra does not start automatically

#reboot