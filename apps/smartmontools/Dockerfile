# syntax=docker/dockerfile:1

FROM docker.io/library/alpine:3.23.7@sha256:ff7f0c727dd796aa36787bfcd9a64bf35a6ce72a73451b3359fde849b6703d63

ARG VERSION

USER root

RUN apk add --no-cache \
    smartmontools=${VERSION}