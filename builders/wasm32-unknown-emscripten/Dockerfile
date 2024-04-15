FROM emscripten/emsdk:3.1.54

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

# Prefer apt-installed nodejs instead of emsdk's old one.
ENV PATH=/usr/bin:$PATH

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
