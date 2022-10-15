#!/bin/bash -ex

if [ -f /boot/boring.env ]; then
	. /boot/boring.env
fi

LOCAL_GATEWAY=$(/sbin/ip route | awk '/default/ { print $3 }')

RESET=false

if [ -f /boot/1boring.env ]; then
	# if files differ, run a reset
	set +e
	/usr/bin/diff /boot/boring.env /boot/1boring.env
	if [[ "$?" != "0" ]]; then
		/usr/bin/diff /boot/boring.env /boot/1boring.env |grep "SETUP_KEY"
		if [[ "$?" == "0" ]]; then
		# setup key was changed, hard reset
			systemctl stop netbird
			rm -rf /etc/netbird/config.json ||true
			rm -rf /etc/sysconfig/netbird ||true
			cp /boot/1boring.env /boot/2boring.env
			RESET=true
			echo reseting
		else
			# setup key was unchanged, soft reset
			# todo, soft reset stuff goes here (SSID, name, network)
			RESET=false
			echo soft reset
		fi
	fi
	set -e
else
	# cause it's firstboot
	RESET=true
	echo firstbooting
fi

cp /boot/boring.env /boot/1boring.env

if [[ "$KIND" == "consumer" ]]; then
	echo "setting up consumer.."
	if [[ "$RESET" == "true" ]]; then
		systemctl stop netbird ||true

		mkdir -p /etc/sysconfig ||true

cat <<EOF > /etc/sysconfig/netbird
PROVIDER_PUBKEY=${PROVIDER_PUBKEY}
EOF

		systemctl start netbird
		sleep 2

		netbird up --setup-key $SETUP_KEY --management-url https://boring.dank.earth:33073
		sleep 5
	fi

	systemctl start netbird ||true
	sleep 20

	sysctl net.ipv4.ip_forward=1
	ip route del default
	ip route add default dev wt0
	for i in ${PUBLIC_PEER_IP_LIST//,/ }
	do
	ip route add $i/32 via $LOCAL_GATEWAY dev eth0
	done
	iptables -t nat -A POSTROUTING -o wt0 -j MASQUERADE
	# masquerade also for any direct traffic to falcon
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	sleep 1

elif [[ "$KIND" == "provider" ]]; then
	echo "setting up provider.."

	if [[ "$RESET" == "true" ]]; then
		systemctl start netbird
		sleep 2

		netbird up --setup-key $SETUP_KEY --management-url https://boring.dank.earth:33073
		sleep 5

		mypubkey=`/usr/bin/wg show all dump |/usr/bin/head -n1 |/usr/bin/cut -f3`

		systemctl stop netbird
		mkdir -p /etc/sysconfig ||true
cat <<EOD > /etc/sysconfig/netbird
PROVIDER_PUBKEY=${mypubkey}
EOD
	fi

	systemctl start netbird || true
	sleep 20 

	sysctl net.ipv4.ip_forward=1
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i wt0 -o eth0 -j ACCEPT
else

	echo "error: invalid \$KIND specified: $KIND"
	exit 1
fi
# telegraf
	# do telegraf setup
	# gather our pubkey
	if [[ "$UPDATE" = "true" ]]; then
		cp /boringup/telegraf.conf /etc/telegraf/telegraf.conf ||true
	fi

	mypubkey=`/usr/bin/wg show all dump |/usr/bin/head -n1 |/usr/bin/cut -f3`
	# telegraf needs perms
	setcap CAP_NET_ADMIN+epi /usr/bin/telegraf
	systemctl stop telegraf ||true
	# setup telegraf id
cat <<EOT > /etc/default/telegraf
INFLUX_TOKEN=QqNqJPMtU3vQk5s-NOOtLU9kQbXZ106181ux7AR6wGOnA7pPVIWtWhvLXT3ai06L_FMcUj2fM1bfsHG_fUFIpw==
BORING_ID=${BORING_ID}
BORING_NAME=${BORING_NAME}
MYPUBKEY=${mypubkey}
EOT
	systemctl start telegraf ||true