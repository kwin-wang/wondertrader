FROM ubuntu:20.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 使用清华镜像源
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list \
    && sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 安装基础开发工具
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    less \
    iproute2 \
    procps \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    curl \
    wget \
    vim \
    gdb \
    cmake \
    build-essential \
    pkg-config \
    ninja-build \
    ccache \
    gcc-8 \
    g++-8 \
    p7zip-full \
    libfltk1.3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置 GCC 8 为默认版本
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 800 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 800 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 800

# 安装项目依赖库
RUN apt-get update && apt-get install -y \
    libboost-all-dev \
    rapidjson-dev \
    libspdlog-dev \
    libnanomsg-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 验证依赖库版本
RUN dpkg -l | grep boost
RUN dpkg -l | grep rapidjson
RUN dpkg -l | grep spdlog
RUN dpkg -l | grep nanomsg

# 设置工作目录
WORKDIR /workspaces/wondertrader

# 添加预编译依赖库，并解压
ADD docker/mydeps_gcc8.4.0.7z /home
RUN cd /home && 7za x mydeps_gcc8.4.0.7z

# 验证 glibc 版本
RUN ldd --version

# 设置环境变量
ENV BOOST_ROOT=/usr
ENV RAPIDJSON_ROOT=/usr
ENV SPDLOG_ROOT=/usr
ENV NANOMSG_ROOT=/usr 