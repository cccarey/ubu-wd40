#!/usr/bin/env bash

function ssh_wait() {
    host=$1
    wait_for=$2
    while [ "`nc -z -w1 ${host} 22; echo $?`" != "${wait_for}" ]; do
        echo -n "."
        sleep 1
    done
    echo ""
}

for machine in $HADOOP_MACHINES
do
    vboxmanage startvm $machine --type=headless
    ssh_wait $machine 0
done

CMD="export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 &&
export HADOOP_HOME=/opt/hadoop &&
/opt/hadoop/sbin/start-dfs.sh && 
/opt/hadoop/sbin/start-yarn.sh"
ssh hduser@hadoopnamenode $CMD
