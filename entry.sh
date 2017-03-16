#!/bin/mksh

set -ex

# get metadata
getmd()
{
    OUT=''
    eval curl "${ENDPOINT}${KEY[$1]}" >$OUT

    printf '%s' "${OUT//\/}"

}

create_config()
{

    export ENDPOINT="http://rancher-metadata/2016-07-29"

    KEY=(
        '/self/container/service_index'
        '/services/consul-comlink/containers'
        '/self/container/name'
        '/self/container/primary_ip'
        '/services/consul-comlink/metadata/enc.key'
        '/self/host/agent_ip'
    )



    SI='' N1='' N2='' AGENT_IP='' CONT_IP='' EK=''
    getmd 1 >$SI
    getmd 5 >$AGENT_IP
    getmd 3 >$CONT_IP
    getmd 4 >$EK

	  cat > /opt/rancher/config/server.json <<EOF
{
$(
if [[ $SI == "1" ]]; then
  print '\t"bootstrap": true,'
else
  print '\t"retry_join": [%s,%s],\n"bootstrap": false,' $N1 $N2
fi
)
    "server": true,
		"datacenter": "comlink",
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
			"dns" : "${DNS}",
			"http" : "${HTTPPORT}",
			"serf_wan": "${SERF_WANPORT}",
			"serf_lan" : "${SERF_LANPORT}",
			"server": "${SERVERPORT}"
		}
}
EOF

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
