FROM elixir:latest
MAINTAINER Mason Fischer
RUN apt-get update
RUN apt-get install -y curl wget
RUN apt-get update
RUN apt-get install -y git build-essential libtool autoconf clang libclang-dev llvm librocksdb-dev
RUN wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz && tar -xf LATEST.tar.gz && cd ./libsodium-stable && ./configure && make && make install
RUN mix local.hex --force && mix local.rebar --force
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
RUN . $HOME/.cargo/env  && rustup default nightly
