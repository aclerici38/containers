# syntax=docker/dockerfile:1

FROM docker.io/library/alpine:3.23.7@sha256:649544f99cfbb1bf2b2a5d19be5c53f76c589b423abf200f3db39d54d03a6f17

ARG VERSION

USER root

RUN apk add --no-cache \
    smartmontools=${VERSION}