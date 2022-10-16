FROM emscripten/emsdk:2.0.13

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git curl build-essential libyaml-dev zlib1g-dev gosu -y; \
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -; \
  apt-get install nodejs -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Build with non-root user because `@npmcli/promise-spawn` sets `uid` and `gid` to cwd owner when the current user is root.
# This permission demotion results in EACCES error at reading `$HOME/.node_modules` in `resolve` package, which is used by `@rollup/plugin-node-resolve`.
# * https://github.com/npm/cli/blob/32336f6efe06bd52de1dc67c0f812d4705533ef2/node_modules/%40npmcli/promise-spawn/lib/index.js#L13
RUN adduser --disabled-password --gecos '' me
