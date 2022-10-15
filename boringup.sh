#!/bin/bash -ex
if [ -f /boot/boring.env ]; then
	. /boot/boring.env
else
	# setup wifi AP
	sysctl net.ipv4.ip_forward=1
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	echo "No /boot/boring.env detected, exiting."
	exit 0
fi 

if [[ "$UPDATE" == "true" ]]; then
	mkdir -p /boringup
	cd /boringup
	until wget https://s3.us-east-2.amazonaws.com/boringfiles.dank.earth/boringfilesintel.tgz
	do
		sleep 5
	done
	tar -xzvf boringfilesintel.tgz
	systemctl stop netbird ||true
	cp netbird /bin/netbird
	cp boring.service /lib/systemd/system/boring.service
	cp boring.sh /usr/local/bin/boring.sh
	rm -f boringfilesintel.tgz
fi

/usr/local/bin/boring.sh
