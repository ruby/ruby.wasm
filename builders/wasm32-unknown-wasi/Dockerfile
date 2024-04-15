FROM debian:bookworm

ARG WASI_PRESET_ARGS_VERSION=0.1.1
ARG NODE_MAJOR_VERSION=20

RUN set -eux; \
  apt-get update; \
  apt-get install -y ca-certificates curl gnupg; \
  mkdir -p /etc/apt/keyrings; \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list; \
  apt-get update; \
  apt-get install ruby ruby-dev ruby-bundler nodejs \
    bison make autoconf git curl build-essential \
    pkg-config libssl-dev \
    libyaml-dev zlib1g-dev gosu \
    libclang-13-dev -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*

RUN set -eux pipefail; \
  wasi_preset_args_url="https://github.com/kateinoigakukun/wasi-preset-args/releases/download/v${WASI_PRESET_ARGS_VERSION}/wasi-preset-args-x86_64-unknown-linux-gnu.zip"; \
  curl -LO "$wasi_preset_args_url"; \
  unzip wasi-preset-args-x86_64-unknown-linux-gnu.zip; \
  mv wasi-preset-args /usr/local/bin/wasi-preset-args

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.75

RUN set -eux pipefail; \
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
  chmod -R a+w $RUSTUP_HOME $CARGO_HOME

ENV BUNDLE_PATH=/usr/local/gems
RUN set -eux; \
  mkdir -p $BUNDLE_PATH; \
  chmod -R 777 $BUNDLE_PATH

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Build with non-root user because `@npmcli/promise-spawn` sets `uid` and `gid` to cwd owner when the current user is root.
# This permission demotion results in EACCES error at reading `$HOME/.node_modules` in `resolve` package, which is used by `@rollup/plugin-node-resolve`.
# * https://github.com/npm/cli/blob/32336f6efe06bd52de1dc67c0f812d4705533ef2/node_modules/%40npmcli/promise-spawn/lib/index.js#L13
RUN adduser --disabled-password --gecos '' me
