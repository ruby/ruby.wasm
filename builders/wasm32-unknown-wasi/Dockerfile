FROM rust:1.57-buster as wit-bindgen-builder

ARG WIT_BINDGEN_REV=dab589f579b980c81b39c8348400b88a8c4d175a
RUN cargo install --git https://github.com/bytecodealliance/wit-bindgen \
  --rev $WIT_BINDGEN_REV \
  --root /tmp/install wit-bindgen-cli

FROM debian:buster

ARG WASI_SDK_VERSION_MAJOR=14
ARG WASI_SDK_VERSION_MINOR=0
ARG BINARYEN_VERSION=91

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
  binaryen_tarball="binaryen-version_${BINARYEN_VERSION}-x86-linux.tar.gz"; \
  binaryen_url="https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/${binaryen_tarball}"; \
  wget -O - "$binaryen_url" | tar xfz -; \
  ln -fs /binaryen-version_${BINARYEN_VERSION} /opt/binaryen;

ENV PATH="$BINARYEN_DIR:$PATH"

COPY --from=wit-bindgen-builder /tmp/install/wit-bindgen /usr/local/bin/wit-bindgen
