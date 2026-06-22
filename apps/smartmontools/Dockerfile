# syntax=docker/dockerfile:1

FROM docker.io/library/alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

ARG VERSION

USER root

RUN apk add --no-cache \
    smartmontools=${VERSION}