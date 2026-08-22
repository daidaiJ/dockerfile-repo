# syntax=docker/dockerfile:1

# ============================================================
# Go 运行时 Base 镜像
# ------------------------------------------------------------
# 适用场景：内网部署，运行时无法在线安装依赖。
# 本镜像在构建阶段一次性预装调试/编辑工具，构建后推送到
# 内网 registry，应用镜像二阶段构建时直接 FROM 引用。
#
# 构建：
#   docker build -t registry.example.com/base/go-runtime:1.0 ./base
# ============================================================

ARG ALPINE_VERSION=3.20
# 基础镜像源：默认毫秒镜像（docker.1ms.run），可换成阿里云/内网 registry
ARG BASE_REGISTRY=docker.1ms.run

FROM ${BASE_REGISTRY}/library/alpine:${ALPINE_VERSION}

# 时区（按需修改）
ENV TZ=Asia/Shanghai

# 预装工具：构建时安装，运行时不依赖网络
# 只保留接口联调/编辑配置的常用工具，网络层排查工具按需取消注释
RUN apk add --no-cache \
        ca-certificates \
        tzdata \
        # ---- 接口联调 ----
        curl \
        wget \
        jq \
        bind-tools \
        # ---- 进程查看 ----
        procps \
        # ---- 编辑 / 配置 ----
        vim \
        yq \
        # ---- 基础 ----
        bash \
        # ---- 可选工具（按需取消注释）----
        # git \
        # lsof \
        # nano \
        # file \
        # tree \
        # netcat-openbsd \
        # socat \
        # tcpdump \
        # strace \
        # htop \
        # iproute2 \
        # openssl \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && rm -rf /var/cache/apk/*

# 非 root 用户（默认以 app 运行；需要 root 调试时 docker run --user root）
RUN addgroup -S app \
    && adduser -S app -G app

USER app

WORKDIR /app