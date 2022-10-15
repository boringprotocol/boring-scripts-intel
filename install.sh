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
wget -q https://repos.influxdata.com/influxdb.key
echo '23a1c8836f0afc5ed24e0486339d7cc8f6790b83886c4c96995b88a061c5bb5d influxdb.key' | sha256sum -c && cat influxdb.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdb.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

apt-get update
apt-get install -y telegraf

echo starting boring
systemctl start boring
