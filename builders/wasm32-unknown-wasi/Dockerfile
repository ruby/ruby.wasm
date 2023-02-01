FROM debian:buster

ARG WASI_SDK_VERSION_MAJOR=14
ARG WASI_SDK_VERSION_MINOR=0
ARG WASI_PRESET_ARGS_VERSION=0.1.1

ENV WASI_SDK_PATH="/opt/wasi-sdk" 

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git curl build-essential libyaml-dev zlib1g-dev gosu -y; \
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -; \
  apt-get install nodejs -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*

RUN set -eux pipefail; \
  wasi_sdk_deb="wasi-sdk_${WASI_SDK_VERSION_MAJOR}.${WASI_SDK_VERSION_MINOR}_amd64.deb"; \
  curl -LO "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION_MAJOR}/${wasi_sdk_deb}"; \
  dpkg -i "$wasi_sdk_deb"; \
  rm -f "$wasi_sdk_deb";

RUN set -eux pipefail; \
  wasi_preset_args_url="https://github.com/kateinoigakukun/wasi-preset-args/releases/download/v${WASI_PRESET_ARGS_VERSION}/wasi-preset-args-x86_64-unknown-linux-gnu.zip"; \
  curl -LO "$wasi_preset_args_url"; \
  unzip wasi-preset-args-x86_64-unknown-linux-gnu.zip; \
  mv wasi-preset-args /usr/local/bin/wasi-preset-args

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Build with non-root user because `@npmcli/promise-spawn` sets `uid` and `gid` to cwd owner when the current user is root.
# This permission demotion results in EACCES error at reading `$HOME/.node_modules` in `resolve` package, which is used by `@rollup/plugin-node-resolve`.
# * https://github.com/npm/cli/blob/32336f6efe06bd52de1dc67c0f812d4705533ef2/node_modules/%40npmcli/promise-spawn/lib/index.js#L13
RUN adduser --disabled-password --gecos '' me
