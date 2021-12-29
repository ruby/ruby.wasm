FROM emscripten/emsdk:2.0.34

RUN set -eux; \
  apt-get update; \
  apt-get install ruby bison make autoconf git -y; \
  apt-get clean; \
  rm -r /var/lib/apt/lists/*
