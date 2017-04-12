FROM consul:0.8.0

RUN apk update --no-cache --purge \
	&& apk add mksh tar git

ENV DNS="${DNS}" HTTPPORT="${HTTPPORT}" SERF_WANPORT="${SERF_WANPORT}" \
SERF_LANPORT="${SERF_LANPORT}" SERVERPORT="${SERVERPORT}" DOMAIN="${DOMAIN}"

ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
