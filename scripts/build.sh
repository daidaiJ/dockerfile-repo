#!/usr/bin/env bash
# 构建并推送 base 镜像到内网 registry
# 用法: REGISTRY=registry.example.com TAG=1.0 ./scripts/build.sh
set -euo pipefail

REGISTRY="${REGISTRY:-registry.example.com}"
TAG="${TAG:-1.0}"
IMAGE="${REGISTRY}/base/go-runtime:${TAG}"

docker build -t "${IMAGE}" "$(dirname "$0")/../base"
docker push "${IMAGE}"

echo "done: ${IMAGE}"