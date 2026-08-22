# syntax=docker/dockerfile:1

# ============================================================
# Go 应用二阶段构建示例
# ------------------------------------------------------------
# Stage 1 编译（构建机有网，可拉依赖）
# Stage 2 运行：只拷贝二进制 + 项目配置到 base 镜像
#
# 构建：
#   docker build -t myapp:1.0 \
#     --build-arg BUILD_PATH=./cmd/server \
#     --build-arg VERSION=1.0.0 \
#     .
# ============================================================

# ---------- Stage 1: Builder ----------
ARG GO_VERSION=1.24
# Go 基础镜像源：默认毫秒镜像，可换成阿里云/内网 registry
ARG GO_REGISTRY=docker.1ms.run

FROM ${GO_REGISTRY}/library/golang:${GO_VERSION}-alpine AS builder

ARG APP_NAME=app
ARG BUILD_PATH=./cmd/server
ARG VERSION=dev
ARG COMMIT=unknown
# Go 模块代理：国内构建加速，内网有私有代理时覆盖
ARG GOPROXY=https://goproxy.cn,direct

WORKDIR /src

# 先拷贝依赖清单，利用 Docker 层缓存加速重复构建
COPY go.mod go.sum ./
ENV GOPROXY=${GOPROXY}
RUN go mod download

COPY . .

# 静态编译：CGO_ENABLED=0 使二进制不依赖 glibc，可直接运行在 alpine 上
RUN CGO_ENABLED=0 GOOS=linux go build \
        -trimpath \
        -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT}" \
        -o /out/${APP_NAME} \
        ${BUILD_PATH}

# ---------- Stage 2: Runtime ----------
# 换成内网 registry 里的 base 镜像
ARG BASE_IMAGE=registry.example.com/base/go-runtime:1.0

FROM ${BASE_IMAGE} AS runtime

ARG APP_NAME=app

# 拷贝编译好的二进制
COPY --from=builder /out/${APP_NAME} /usr/local/bin/${APP_NAME}

# 拷贝项目配置（没有 configs/ 目录就删掉这行）
COPY configs/ /app/configs/

# 按需启用：
# EXPOSE 8080
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#     CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["/usr/local/bin/app"]