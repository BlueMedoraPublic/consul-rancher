FROM consul:0.7.5

ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
