# Go 二阶段构建 Dockerfile 模板

面向**内网部署**场景的 Go 服务 Dockerfile 模板：二阶段构建，运行层使用预装调试/编辑工具的 base 镜像，避免在运行时（内网）在线安装依赖。基础镜像默认走**毫秒镜像**（docker.1ms.run）加速拉取。

## 目录结构

```
dockerfile-repo/
├── base/
│   └── Dockerfile        # 运行时 base 镜像：预装调试/编辑工具，构建一次推送到内网 registry
├── app/
│   ├── Dockerfile        # 应用二阶段构建示例（builder + base）
│   └── .dockerignore
├── scripts/
│   └── build.sh          # base 镜像构建/推送脚本
└── README.md
```

## 工作流

1. **构建 base 镜像**（构建机有网，只需一次）：

   ```bash
   docker build -t registry.example.com/base/go-runtime:1.0 ./base
   docker push registry.example.com/base/go-runtime:1.0
   ```

2. **应用镜像**（内网构建机）：

   ```bash
   docker build -t myapp:1.0 \
     --build-arg BUILD_PATH=./cmd/server \
     --build-arg VERSION=1.0.0 \
     .
   ```

   应用 Dockerfile 的 Stage 2 直接 `FROM registry.example.com/base/go-runtime:1.0`，工具已内置，运行时无需任何安装。

## 镜像源配置

两个 Dockerfile 都通过 ARG 指定基础镜像源，默认**毫秒镜像**：

| 镜像源 | 值（BASE_REGISTRY / GO_REGISTRY） |
|--------|-----------------------------------|
| 毫秒镜像（默认） | `docker.1ms.run` |
| 阿里云 | `registry.cn-hangzhou.aliyuncs.com/library` |
| DaoCloud | `docker.m.daocloud.io` |
| 中科大 | `docker.mirrors.ustc.edu.cn` |

官方镜像统一走 `/library/` 前缀（如 `docker.1ms.run/library/alpine:3.20`），以上镜像源均兼容。切换方式：

```bash
# 构建 base 时指定镜像源
docker build --build-arg BASE_REGISTRY=registry.cn-hangzhou.aliyuncs.com/library -t base/go-runtime:1.0 ./base

# 构建应用时指定 Go 镜像源
docker build --build-arg GO_REGISTRY=registry.cn-hangzhou.aliyuncs.com/library .
```

内网有自建 registry 时，把镜像提前拉下来推上去，再把 ARG 指向内网地址即可。

## Go 模块代理

builder 阶段默认 `GOPROXY=https://goproxy.cn,direct`，内网有私有代理（Athens/Artifactory 等）时覆盖：

```bash
docker build --build-arg GOPROXY=http://goproxy.internal:3000 .
```

## base 镜像内置工具

| 类别 | 工具 |
|------|------|
| 网络调试 | curl, wget, netcat-openbsd, socat, tcpdump, dig(bind-tools), ss/ip(iproute2), openssl |
| 进程/性能 | ps/top(procps), htop, strace |
| 编辑/配置 | vim, jq, yq |
| 基础 | bash, ca-certificates, tzdata |

需要更多工具（git、lsof、nano 等）时，取消 base/Dockerfile 中对应注释行即可。

## 说明

- **静态编译**：builder 阶段 `CGO_ENABLED=0`，产物不依赖 glibc，可直接运行在 alpine 上。
- **非 root 运行**：base 默认 `USER app`；需要 root 调试时 `docker run --user root`。
- **时区**：默认 `Asia/Shanghai`，按需修改 base/Dockerfile 中的 `TZ`。
- **版本注入**：`-ldflags "-X main.version=..."` 需要应用代码里声明 `var version string`，不需要可去掉。
- **生产精简版**：不需要调试工具时，Stage 2 直接 `FROM alpine:3.20` 或 `FROM gcr.io/distroless/static-debian12:nonroot`，体积更小。

## 常见问题

- **内网没有 golang 镜像**：把 `golang:1.24-alpine` 也提前拉到内网 registry，改 `GO_REGISTRY` 指向内网地址。
- **端口 <1024**：非 root 用户无法绑定 80/443，用 `--user root` 或改用高位端口。