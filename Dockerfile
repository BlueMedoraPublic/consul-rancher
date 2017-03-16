FROM consul:0.7.5

RUN apk update --no-cache --purge \
    apk install mksh tar git

ENV DNS="${DNS}" HTTPPORT="${HTTPPORT}" SERF_WANPORT="${SERF_WANPORT}" \
SERF_LANPORT="${SERF_LANPORT}" SERVERPORT="${SERVERPORT}"

ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
