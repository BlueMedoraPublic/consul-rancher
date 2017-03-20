#!/bin/mksh

set -vx
set -o pipefail

# get metadata
getmd()
{
		OUT=''
		OUT=$(eval curl "${ENDPOINT}${KEY[$1]}")

		print "${OUT}" | sed -e 's/[0-9]=//g'

}

create_config()
{

		export ENDPOINT="http://169.254.169.250/2016-07-29"

		KEY=(
				"/self/container/service_index"
				"/self/service/containers"
				"/self/container/name"
				"/self/container/primary_ip"
				"/services/${DC}/metadata/enc.key"
				"/self/host/agent_ip"
				"/self/service/scale"
		)

		SI='' N1='' N2='' AGENT_IP='' CONT_IP='' EK=''
		SI=${ getmd 0; }
		AGENT_IP=${ getmd 5; }
		CONT_IP=${ getmd 3; }
		EK=${ getmd 4; }
		CONTS=( ${ getmd 1; } )
		SCALE=${ getmd 6; }


		cat > /opt/rancher/config/server.json <<EOF
{
$(
for x in ${!CONTS[@]}; do
TMPCONTS+=\"${CONTS[$x]}.${DOMAIN:=rancher.internal}\",
done
print '\t'\"retry_join\" : [ ${TMPCONTS%,} ],
)
	"bootstrap_expect": ${SCALE:=3},
	"server": true,
	"datacenter": "${DC}",
	"advertise_addr": "${AGENT_IP}",
	"bind_addr": "0.0.0.0",
	"client_addr": "0.0.0.0",
	"data_dir": "/var/consul",
	"encrypt": "${EK}",
	"ca_file": "/opt/rancher/ssl/ca.crt",
	"cert_file": "/opt/rancher/ssl/consul.crt",
	"key_file": "/opt/rancher/ssl/consul.key",
	"verify_incoming": true,
	"verify_outgoing": true,
	"log_level": "INFO",
	"ports" : {
		"dns" : ${DNS:=8600},
		"http" : ${HTTPPORT:=8500},
		"serf_wan": ${SERF_WANPORT:=8302},
		"serf_lan" : ${SERF_LANPORT:=8301},
		"server": ${SERVERPORT:=8300}
	},
	"performance": {
		"raft_multiplier": 1
	}
}
EOF
		cat /opt/rancher/config/server.json

}

run_consul()
{
		exec consul agent -server -ui -config-file=/opt/rancher/config/server.json -data-dir=/var/consul
}

main()
{

		create_config

		sleep 10
		run_consul
}

main
