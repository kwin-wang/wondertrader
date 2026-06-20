#!/usr/bin/env bash
set -e

# macOS: Homebrew 的 spdlog 移除了自带的 bundled fmt, 而本项目依赖
# <spdlog/fmt/bundled/format.h>, 故使用 vendored 的 spdlog 1.9.2。
# 若不存在则自动拉取。
if [ "$(uname)" = "Darwin" ]; then
    SPDLOG_DIR="../third-party/spdlog-src"
    if [ ! -f "$SPDLOG_DIR/include/spdlog/fmt/bundled/format.h" ]; then
        echo "vendored spdlog 不存在, 正在拉取 spdlog v1.9.2 ..."
        git clone --depth 1 -b v1.9.2 https://github.com/gabime/spdlog.git "$SPDLOG_DIR"
    fi
    JOBS=$(sysctl -n hw.ncpu)
else
    JOBS=$(nproc)
fi

if [ ! -d "./build_all" ];then
mkdir build_all
fi
cd build_all
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j ${JOBS}
