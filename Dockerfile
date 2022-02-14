FROM golang:1.15 as builder
COPY inc/ /
RUN cd /sensu-telegram-handler && go build -o sensu-telegram-handler main.go

# Change this to a git tag if you wish
ENV git_tag=v6.6.4

WORKDIR /build
RUN apt-get update -q && \
    apt-get install -y git && \
    git clone --depth=1 --single-branch --branch ${git_tag} https://github.com/sensu/sensu-go.git

RUN cd sensu-go && \
    mkdir ../bin && \
    go build -ldflags "-X "github.com/sensu/sensu-go/version.Version=${git_tag}" -X "github.com/sensu/sensu-go/version.BuildDate=$(date +"%y-%m-%d")" -X "github.com/sensu/sensu-go/version.BuildSHA=$(git rev-parse HEAD)"" -o ../bin/sensu-agent ./cmd/sensu-agent && \
    go build -ldflags "-X "github.com/sensu/sensu-go/version.Version=${git_tag}" -X "github.com/sensu/sensu-go/version.BuildDate=$(date +"%y-%m-%d")" -X "github.com/sensu/sensu-go/version.BuildSHA=$(git rev-parse HEAD)"" -o ../bin/sensu-backend ./cmd/sensu-backend && \
    go build -ldflags "-X "github.com/sensu/sensu-go/version.Version=${git_tag}" -X "github.com/sensu/sensu-go/version.BuildDate=$(date +"%y-%m-%d")" -X "github.com/sensu/sensu-go/version.BuildSHA=$(git rev-parse HEAD)"" -o ../bin/sensuctl ./cmd/sensuctl


FROM ubuntu:20.04

COPY --from=builder /sensu-telegram-handler/sensu-telegram-handler /usr/bin/sensu-telegram-handler
COPY --from=builder /build/bin /opt/sensu/bin/


RUN apt-get update -q && apt-get install -y curl wget \
    && curl -L -kO https://github.com/sensu/sensu-email-handler/releases/download/0.2.0/sensu-email-handler_0.2.0_linux_386.tar.gz  \
    && tar xvf sensu-email-handler_0.2.0_linux_386.tar.gz && mv bin/sensu-email-handler /usr/local/bin/

ENV PATH /opt/sensu/bin:$PATH