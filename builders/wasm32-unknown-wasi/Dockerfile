FROM rust:1.57-buster as wit-bindgen-builder

ARG WIT_BINDGEN_REV=bb33644b4fd21ecf43761f63c472cdfffe57e300
RUN cargo install --git https://github.com/bytecodealliance/wit-bindgen \
  --rev $WIT_BINDGEN_REV \
  --root /tmp/install wit-bindgen-cli

FROM debian:buster

ARG WASI_SDK_VERSION_MAJOR=14
ARG WASI_SDK_VERSION_MINOR=0
ARG BINARYEN_VERSION=108
ARG WASI_VFS_VERSION=0.1.1
ARG WASI_PRESET_ARGS_VERSION=0.1.1

ENV WASI_SDK_PATH="/opt/wasi-sdk" 

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git curl build-essential libyaml-dev zlib1g-dev -y; \
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -; \
  apt-get install nodejs -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*

RUN set -eux pipefail; \
  wasi_sdk_deb="wasi-sdk_${WASI_SDK_VERSION_MAJOR}.${WASI_SDK_VERSION_MINOR}_amd64.deb"; \
  curl -LO "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION_MAJOR}/${wasi_sdk_deb}"; \
  dpkg -i "$wasi_sdk_deb"; \
  rm -f "$wasi_sdk_deb";

ENV BINARYEN_DIR="/opt/binaryen"
RUN set -eux pipefail; \
  binaryen_tarball="binaryen-version_${BINARYEN_VERSION}-x86_64-linux.tar.gz"; \
  binaryen_url="https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/${binaryen_tarball}"; \
  curl -L "$binaryen_url" | tar xfz -; \
  ln -fs /binaryen-version_${BINARYEN_VERSION} /opt/binaryen;

ENV PATH="$BINARYEN_DIR/bin:$PATH"

ENV LIB_WASI_VFS_A="/opt/wasi-vfs/lib/libwasi_vfs.a"
RUN set -eux pipefail; \
  lib_wasi_vfs_url="https://github.com/kateinoigakukun/wasi-vfs/releases/download/v${WASI_VFS_VERSION}/libwasi_vfs-wasm32-unknown-unknown.zip"; \
  curl -LO "$lib_wasi_vfs_url"; \
  unzip libwasi_vfs-wasm32-unknown-unknown.zip; \
  mkdir -p /opt/wasi-vfs/lib; \
  mv libwasi_vfs.a $LIB_WASI_VFS_A; \
  wasi_vfs_cli_url="https://github.com/kateinoigakukun/wasi-vfs/releases/download/v${WASI_VFS_VERSION}/wasi-vfs-cli-x86_64-unknown-linux-gnu.zip"; \
  curl -LO "$wasi_vfs_cli_url"; \
  unzip wasi-vfs-cli-x86_64-unknown-linux-gnu.zip; \
  mv wasi-vfs /usr/local/bin/wasi-vfs; \
  wasi_preset_args_url="https://github.com/kateinoigakukun/wasi-preset-args/releases/download/v${WASI_PRESET_ARGS_VERSION}/wasi-preset-args-x86_64-unknown-linux-gnu.zip"; \
  curl -LO "$wasi_preset_args_url"; \
  unzip wasi-preset-args-x86_64-unknown-linux-gnu.zip; \
  mv wasi-preset-args /usr/local/bin/wasi-preset-args

COPY --from=wit-bindgen-builder /tmp/install/bin/wit-bindgen /usr/local/bin/wit-bindgen
