# TODO: FROM ubuntu did not work since `curl https://wasmtime.dev/install.sh -sSf | bash` does not install wasmtime (see https://docs.wasmtime.dev/cli-install.html)

# use `--platform linux/x86_64` when running on ARM
FROM renefonseca/wasmtime

RUN apt-get update && apt-get install curl unzip -y

ENV WASI_VFS_VERSION=0.1.0
RUN curl -LO "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v${WASI_VFS_VERSION}/wasi-vfs-cli-x86_64-unknown-linux-gnu.zip"
RUN unzip wasi-vfs-cli-x86_64-unknown-linux-gnu.zip
RUN mv wasi-vfs /usr/local/bin/wasi-vfs

# Download a prebuilt Ruby release
RUN curl -LO https://github.com/kateinoigakukun/ruby.wasm/releases/download/2022-03-28-a/ruby-head-wasm32-unknown-wasi-full.tar.gz
RUN tar xfz ruby-head-wasm32-unknown-wasi-full.tar.gz

# Extract ruby binary not to pack itself
RUN mv head-wasm32-unknown-wasi-full/usr/local/bin/ruby ruby.wasm

# Put your app code
RUN mkdir src
RUN echo "puts 'Hello'" > src/my_app.rb

# Pack the whole directory under /usr and your app dir
RUN wasi-vfs pack ruby.wasm --mapdir /src::./src --mapdir /usr::./head-wasm32-unknown-wasi-full/usr -o my-ruby-app.wasm

# Run the packed scripts
# TODO: hangs forever
CMD wasmtime my-ruby-app.wasm -- src/my_app.rb
