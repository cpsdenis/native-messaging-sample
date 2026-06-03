FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

COPY . /nmcpp

WORKDIR /nmcpp

RUN make clean && make install