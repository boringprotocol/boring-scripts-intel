#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo grabbing boring
wget https://s3.us-east-2.amazonaws.com/boringfiles.dank.earth/boringfilesintel.tgz
apt install ca-certificates curl gnupg -y

echo grabbing wireguard, netbird
curl -L https://pkgs.wiretrustee.com/debian/public.key | sudo apt-key add -
echo 'deb https://pkgs.wiretrustee.com/debian stable main' | sudo tee /etc/apt/sources.list.d/wiretrustee.list
apt-get update

apt install -y wireguard wireguard-tools net-tools
apt-get install -y netbird

systemctl stop netbird

echo copying boring files...
mkdir boringfiles
cd boringfiles/
tar -xzvf ../boringfilesintel.tgz

cp netbird /bin/netbird
cp boring.service /lib/systemd/system/boring.service
cp boringup.sh /usr/local/bin/boringup.sh
cp boring.sh /usr/local/bin/boring.sh

systemctl enable boring

echo installing influx
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

apt-get update
apt-get install -y telegraf

echo starting boring
systemctl start boring
