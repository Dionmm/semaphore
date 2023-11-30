# ansible-semaphore production image
FROM --platform=$BUILDPLATFORM golang:1.19-alpine3.18 as builder
ARG SEMAPHORE_VERSION
ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache curl git && \
git clone https://github.com/ansible-semaphore/semaphore.git /go/src/github.com/ansible-semaphore/semaphore

WORKDIR /go/src/github.com/ansible-semaphore/semaphore

RUN git checkout v${SEMAPHORE_VERSION} && mv ./deployment/docker/common/semaphore-wrapper /usr/local/bin/semaphore-wrapper && \
curl -L https://github.com/ansible-semaphore/semaphore/releases/download/v${SEMAPHORE_VERSION}/semaphore_${SEMAPHORE_VERSION}_linux_arm64.tar.gz -o semaphore.tar.gz && \ 
tar xf semaphore.tar.gz && \
mv ./semaphore /usr/local/bin/semaphore

FROM alpine:3.18 as runner
LABEL maintainer="Dion MacIntyre <dion.macintyre@gmail.com>"
COPY --from=builder /usr/local/bin/semaphore-wrapper /usr/local/bin/
COPY --from=builder /usr/local/bin/semaphore /usr/local/bin/

RUN apk add --no-cache sshpass git curl ansible mysql-client openssh-client-default tini py3-aiohttp && \
    mkdir -p /tmp/semaphore && \
    mkdir -p /etc/semaphore && \
    mkdir -p /var/lib/semaphore && \
    chmod +x /usr/local/bin/semaphore-wrapper &&\
    chmod +x /usr/local/bin/semaphore

WORKDIR /home/semaphore

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/semaphore-wrapper", "/usr/local/bin/semaphore", "server", "--config", "/etc/semaphore/config.json"]