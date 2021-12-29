FROM emscripten/emsdk:3.1.0

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*
