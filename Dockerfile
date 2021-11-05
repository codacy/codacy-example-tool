FROM alpine:3.14.2

COPY tool.sh /opt/docker/
COPY docs/ /docs/
RUN apk add bash &&\
    wget -q -O /tmp/jq-linux64 https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 &&\
    chmod a+x /tmp/jq-linux64 && mv /tmp/jq-linux64 /usr/bin/jq

RUN adduser -u 2004 -D docker
RUN chown -R docker:docker /docs

CMD [ "bash", "/opt/docker/tool.sh" ]
