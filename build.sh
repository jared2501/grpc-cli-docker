#!/usr/bin/env sh
set -euo pipefail
IFS=$'\n\t'

version=$(git describe --tags)
versioned_image="jared2501/grpc-cli:${version}"
should_publish=${1:-}

cd "$(dirname "$0")"

dockerfile=$(cat <<-'END'
FROM debian:stretch-slim
RUN apt-get update && apt-get install -y \
  build-essential autoconf git pkg-config \
  automake libtool curl make g++ unzip \
  libgflags-dev
ENV GRPC_RELEASE_TAG v1.12.1
RUN git clone -b ${GRPC_RELEASE_TAG} https://github.com/grpc/grpc /var/local/git/grpc
RUN cd /var/local/git/grpc && \
  git submodule update --init && \
  make -j$(nproc) grpc_cli

FROM debian:stretch-slim
ENV GRPC_DEFAULT_SSL_ROOTS_FILE_PATH /etc/ssl/certs/ca-certificates.crt
RUN apt-get update && apt-get install -y \
  ca-certificates libgflags-dev && apt-get clean
COPY --from=0 /var/local/git/grpc/bins/opt/grpc_cli .
CMD ["./grpc_cli"]
END
)

echo "${dockerfile}" | docker build -t "${versioned_image}" . -f -

if [[ "${should_publish}" = "publish" ]]; then
  docker push "${versioned_image}"
fi
