#!/usr/bin/env bash

set -eox pipefail

mkdir /tmp/dl
cd /tmp/dl

curl -L -O https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION_FULL}-arm64-linux.deb && \
curl -L -O https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION_FULL}-x86_64-linux.deb && \

case `dpkg --print-architecture` in
    amd64) dpkg -i wasi-sdk-*-x86_64-linux.deb ;;
    arm64) dpkg -i wasi-sdk-*-arm64-linux.deb ;;
    *) exit 1 ;;
esac

cd /tmp/
rm -rf /tmp/dl