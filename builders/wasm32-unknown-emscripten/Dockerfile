FROM rust:1.57-buster as wit-bindgen-builder

ARG WIT_BINDGEN_REV=dab589f579b980c81b39c8348400b88a8c4d175a
RUN cargo install --git https://github.com/bytecodealliance/wit-bindgen \
  --rev $WIT_BINDGEN_REV \
  --root /tmp/install wit-bindgen-cli

FROM emscripten/emsdk:2.0.13

COPY --from=wit-bindgen-builder /tmp/install/bin/wit-bindgen /usr/local/bin/wit-bindgen

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*
