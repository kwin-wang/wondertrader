{
  description = "WonderTrader 开发环境 (macOS / arm64, 通过 Nix 钉住依赖版本)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # 本项目依赖 spdlog 自带的 bundled fmt(<spdlog/fmt/bundled/format.h>),
    # 新版 spdlog 已移除该目录, 故钉住 1.9.2 源码(header-only 使用)。
    spdlog-src = {
      url = "github:gabime/spdlog/v1.9.2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, spdlog-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # 本项目依赖 boost 的 io_service 等接口, boost>=1.87 已移除。
        # boost183(1.83)仍保留这些接口, 满足需求。
        boost = pkgs.boost183;

        # 把 boost 的 dev(头文件)与主输出(库)合并成单一前缀,
        # 以便 CMake 中 ${BOOST_ROOT}/include 与 ${BOOST_ROOT}/lib 都成立。
        boostJoined = pkgs.symlinkJoin {
          name = "boost-joined";
          paths = [ boost.dev boost.out ];
        };

        # 同样把各依赖合并成一个前缀, 供 CMake 的 WT_DEPS_PREFIX 使用。
        depsPrefix = pkgs.symlinkJoin {
          name = "wt-deps-prefix";
          paths = [
            pkgs.nanomsg
            pkgs.rapidjson
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.cmake
            pkgs.pkg-config
            pkgs.nanomsg
            pkgs.rapidjson
            boost
          ];

          # Nix 的 clang wrapper 默认开启 format-security 等加固标志(-Werror=format-security),
          # 而项目按 Apple clang/Homebrew 默认(不开启)编写。关闭以对齐, 避免误报为错误。
          hardeningDisable = [ "format" ];

          # 注入给 src/CMakeLists.txt 的环境变量(见其中的 ENV{...} 分支)
          WT_DEPS_PREFIX = "${depsPrefix}";
          BOOST_ROOT = "${boostJoined}";
          WT_SPDLOG_INCLUDE = "${spdlog-src}/include";

          shellHook = ''
            echo "WonderTrader Nix devShell (${system})"
            echo "  boost      : ${boost.version}  -> $BOOST_ROOT"
            echo "  spdlog(hdr): 1.9.2(bundled fmt) -> $WT_SPDLOG_INCLUDE"
            echo "  deps prefix: $WT_DEPS_PREFIX"
            echo "  nanomsg    : ${pkgs.nanomsg.version}"
            echo "  rapidjson  : ${pkgs.rapidjson.version}"
            echo ""
            echo "构建: cd src && ./build_release.sh"
          '';
        };
      });
}
