#!/usr/bin/env bash

function progress() {
    # $1 - the progress message
    echo -e "\E[32m============================="
    echo -e "\E[32mSTEP: $1"
    echo -en "\E[0m"
}

function die() {
    # $1 - the exit code
    # $2 $... - the message string

    retcode=$1
    (( $retcode == 0 )) || echo -en "\E[31mERROR: "
    echo "$2"
    (( $retcode == 0 )) || echo -en "\E[0m"
    exit $retcode
}

# based on instructions from https://www.digitalocean.com/community/tutorials/how-to-install-prometheus-on-ubuntu-16-04

# step 1 - create users

progress "create users"
sudo useradd --no-create-home --shell /bin/false prometheus || die 1 "unable to create user prometheus"
sudo useradd --no-create-home --shell /bin/false node_exporter || die 1 "unable to create user node_exporter"

sudo mkdir /etc/prometheus || die 1 "unable to create folder /etc/prometheus"
sudo mkdir /var/lib/prometheus || die 1 "unable to create folder /var/lib/prometheus"

sudo chown prometheus:prometheus /etc/prometheus || die 1 "unable to change owner for folder /etc/prometheus"
sudo chown prometheus:prometheus /var/lib/prometheus || die 1 "unable to change owner for folder /var/lib/prometheus"

# step 2 - download prometheus & node_exporter

progress "download prometheus"
cd /tmp
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.6.0/prometheus-2.6.0.linux-amd64.tar.gz || die 1 "unable to download prometheus"

progress "download node_exporter"
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz || die 1 "unable to download node_exporter"

progress "extract prometheus"
tar xf prometheus-2.6.0.linux-amd64.tar.gz || die 1 "unable to extract prometheus tar ball"

progress "export node_exporter"
tar xf node_exporter-0.17.0.linux-amd64.tar.gz || die 1 "unable to extract node_exporter tar ball"

progress "install files"
sudo cp prometheus-2.6.0.linux-amd64/prometheus /usr/local/bin || die 1 "unable to copy prometheus to /usr/local/bin"
sudo cp prometheus-2.6.0.linux-amd64/promtool /usr/local/bin || die 1 "unable to copy promtool to /usr/local/bin"
sudo cp -r prometheus-2.6.0.linux-amd64/consoles /etc/prometheus || die 1 "unable to copy consoles to /etc/prometheus"
sudo cp -r prometheus-2.6.0.linux-amd64/console_libraries /etc/prometheus || die 1 "unable to copy console_libraries to /etc/prometheus"
sudo cp node_exporter-0.17.0.linux-amd64/node_exporter /usr/local/bin || die 1 "unable to copy node_exporter to /usr/local/bin"

progress "set permissions"
sudo chown prometheus:prometheus /usr/local/bin/prometheus || die 1 "unable to change owner for prometheus"
sudo chown prometheus:prometheus /usr/local/bin/promtool || die 1 "unable to change owner for folder promtool"
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter || die 1 "unable to change owner of node_exporter"

# step 3 - configure

progress "configure prometheus"
cat  > prometheus.yml << END
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9000']
  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
END

sudo mv prometheus.yml /etc/prometheus
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml || die 1 "unable to change owner for /etc/prometheus/prometheus.yml"

# step 4 - install services and start

progress "install prometheus service"
sudo cat > prometheus.service << END
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --storage.tsdb.retention 90d \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
END

sudo mv prometheus.service /etc/systemd/system
sudo chown prometheus:prometheus /etc/systemd/system/prometheus.service

progress "install node_exporter service"
cat > node_exporter.service << END
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
END

sudo mv node_exporter.service /etc/systemd/system
sudo chown node_exporter:node_exporter /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload || die 1 "error restarting systemd. this is a big deal."
sudo systemctl start prometheus || die 1 "error starting prometheus service"
sudo systemctl start node_exporter || die 1 "error starting node_exporter service"

sudo systemctl enable prometheus || die 1 "error enabling prometheus service"
sudo systemctl enable node_exporter || die 1 "error enabling node_exporter service"

# install grafana

progress "install grafana"
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.grafana.com/oss/deb stable main"
sudo apt --quiet update
sudo apt --quiet -y install grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
