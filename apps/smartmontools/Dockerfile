# syntax=docker/dockerfile:1

FROM docker.io/library/alpine:3.23.7@sha256:eaa20f3de212fa5cda0c64dc715b55ce28619928536d0d2a97ec1a922c1edce8

ARG VERSION

USER root

RUN apk add --no-cache \
    smartmontools=${VERSION}