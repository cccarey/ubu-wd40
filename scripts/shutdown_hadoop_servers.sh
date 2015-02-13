#!/usr/bin/env bash
SUDOPASSWD=""
PASSCH="check"
while [ "$SUDOPASSWD" != "$PASSCH" ]; do
    echo -n "Enter sudo password: "
    read -s SUDOPASSWD
    echo

    echo -n "Re-enter password..: "
    read -s PASSCH
    echo
done

CMD="export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 &&
export HADOOP_HOME=/opt/hadoop &&
/opt/hadoop/sbin/stop-yarn.sh && 
/opt/hadoop/sbin/stop-dfs.sh"
ssh hduser@hadoopnamenode $CMD

CMD="echo $SUDOPASSWD | sudo -S shutdown -P 0"
for vm in $HADOOP_MACHINES
do
    ssh $vm $CMD
done
