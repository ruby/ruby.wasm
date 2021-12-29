FROM debian:buster

ARG WASI_SDK_VERSION_MAJOR=14
ARG WASI_SDK_VERSION_MINOR=0
ARG BINARYEN_VERSION=104

ENV WASI_SDK_PATH="/opt/wasi-sdk" 

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git wget -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*

RUN set -eux pipefail; \
  wasi_sdk_deb="wasi-sdk_${WASI_SDK_VERSION_MAJOR}.${WASI_SDK_VERSION_MINOR}_amd64.deb"; \
  wget "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION_MAJOR}/${wasi_sdk_deb}"; \
  dpkg -i "$wasi_sdk_deb"; \
  rm -f "$wasi_sdk_deb";

ENV BINARYEN_DIR="/opt/binaryen"
RUN set -eux pipefail; \
  binaryen_tarball="binaryen-version_${BINARYEN_VERSION}-x86_64-linux.tar.gz"; \
  binaryen_url="https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/${binaryen_tarball}"; \
  wget -O - "$binaryen_url" | tar xfz -; \
  ln -fs /binaryen-version_${BINARYEN_VERSION} /opt/binaryen;

ENV PATH="$BINARYEN_DIR/bin:$PATH"

