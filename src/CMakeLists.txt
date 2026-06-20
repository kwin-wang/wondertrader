CMAKE_MINIMUM_REQUIRED(VERSION 3.10)

PROJECT(WonderTrader)

#3. 环境判断
IF (WIN32)
	MESSAGE(STATUS "Operation System is windows")
ELSEIF (APPLE)
	MESSAGE(STATUS "Operation System is macOS")
ELSEIF (UNIX)
	MESSAGE(STATUS "Operation System is UNIX-like OS's")
ENDIF ()

MESSAGE(STATUS "Generator is ${CMAKE_GENERATOR}")

IF (MSVC)
	ADD_DEFINITIONS (-D_CRT_SECURE_NO_WARNINGS)
	IF(CMAKE_CL_64)
		SET(INCS $ENV{MyDepends141}/include)
		SET(LNKS $ENV{MyDepends141}/lib/x64)

		MESSAGE(STATUS "MyDepends is at $ENV{MyDepends141}")
		MESSAGE(STATUS "Platform is x64")
		SET(PLATFORM x64)
	ELSE()
		SET(INCS $ENV{MyDepends141}/include)
		SET(LNKS $ENV{MyDepends141}/lib/x86)

		MESSAGE(STATUS "MyDepends is at $ENV{MyDepends141}")
		MESSAGE(STATUS "Platform is x86")
		SET(PLATFORM x86)
	ENDIF()
	SET(PREFIX )
	SET(SUFFIX .dll)
ELSEIF (APPLE)
	SET(SUFFIX .dylib)
	# Nix devShell通过环境变量WT_DEPS_PREFIX注入依赖前缀,此时跳过Homebrew探测
	IF(NOT DEFINED BREW_PREFIX AND DEFINED ENV{WT_DEPS_PREFIX})
		SET(BREW_PREFIX $ENV{WT_DEPS_PREFIX})
		MESSAGE(STATUS "Using deps prefix from environment (Nix): ${BREW_PREFIX}")
	ENDIF()
	# 自动探测Homebrew前缀(Apple Silicon为/opt/homebrew, Intel为/usr/local)
	IF(NOT DEFINED BREW_PREFIX)
		FIND_PROGRAM(BREW_EXECUTABLE brew)
		IF(BREW_EXECUTABLE)
			EXECUTE_PROCESS(COMMAND ${BREW_EXECUTABLE} --prefix
				OUTPUT_VARIABLE BREW_PREFIX
				OUTPUT_STRIP_TRAILING_WHITESPACE)
		ELSEIF(EXISTS "/opt/homebrew")
			SET(BREW_PREFIX "/opt/homebrew")
		ELSE()
			SET(BREW_PREFIX "/usr/local")
		ENDIF()
	ENDIF()
	SET(MyDeps "${BREW_PREFIX}")
	SET(INCS ${MyDeps}/include)
	SET(LNKS ${MyDeps}/lib)
	SET(PLATFORM x64)
	SET(PREFIX lib)
	MESSAGE(STATUS "MyDepends is at ${MyDeps}")

	# 本项目依赖spdlog自带的bundled fmt(<spdlog/fmt/bundled/format.h>),而Homebrew
	# 和Nix的spdlog均已移除它,故使用vendored的spdlog 1.9.2头文件。
	# Nix devShell通过WT_SPDLOG_INCLUDE注入,否则回退到仓库内third-party目录。
	IF(DEFINED ENV{WT_SPDLOG_INCLUDE})
		SET(VENDORED_SPDLOG $ENV{WT_SPDLOG_INCLUDE})
	ELSE()
		SET(VENDORED_SPDLOG ${CMAKE_SOURCE_DIR}/../third-party/spdlog-src/include)
	ENDIF()
	IF(EXISTS ${VENDORED_SPDLOG}/spdlog/fmt/bundled/format.h)
		INCLUDE_DIRECTORIES(BEFORE ${VENDORED_SPDLOG})
		MESSAGE(STATUS "Using vendored spdlog at ${VENDORED_SPDLOG}")
	ENDIF()

	# 本项目依赖boost的io_service等接口,boost>=1.87已移除。
	# Nix通过BOOST_ROOT(环境变量)注入含该接口的boost(如1.83);
	# 否则在Homebrew中查找keg-only的boost@1.85等旧版本。
	IF(NOT DEFINED BOOST_ROOT AND DEFINED ENV{BOOST_ROOT})
		SET(BOOST_ROOT $ENV{BOOST_ROOT})
	ENDIF()
	IF(NOT DEFINED BOOST_ROOT)
		FOREACH(_bver 1.85 1.84 1.83 1.82 1.81 1.80 1.72)
			IF(EXISTS ${BREW_PREFIX}/opt/boost@${_bver}/include/boost/asio/io_service.hpp)
				SET(BOOST_ROOT ${BREW_PREFIX}/opt/boost@${_bver})
				BREAK()
			ENDIF()
		ENDFOREACH()
	ENDIF()
	IF(BOOST_ROOT)
		INCLUDE_DIRECTORIES(BEFORE ${BOOST_ROOT}/include)
		LINK_DIRECTORIES(${BOOST_ROOT}/lib)
		MESSAGE(STATUS "Using boost at ${BOOST_ROOT}")
	ELSE()
		MESSAGE(WARNING "未找到含io_service的boost(如boost@1.85),可能编译失败。请执行: brew install boost@1.85")
	ENDIF()

	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
ELSE (GNUCC)
	IF(WIN32)
		SET (MyDeps $ENV{MyDependsGcc})
		SET(SUFFIX .dll)

		MESSAGE(STATUS "MyDepends is at $ENV{MyDependsGcc}")
	ELSE(UNIX)
		SET (MyDeps "/home/mydeps")
		SET(SUFFIX .so)

		MESSAGE(STATUS "MyDepends is at /home/mydeps")
	ENDIF()

	SET(INCS ${MyDeps}/include)
	SET(LNKS ${MyDeps}/lib)

	MESSAGE(STATUS "Platform is x64")
	SET(PLATFORM x64)
	SET(PREFIX lib)
ENDIF()

SET(CMAKE_CXX_STANDARD 17)

# filesystem链接库: Linux GCC用stdc++fs(std::filesystem); 但部分模块实际使用
# boost::filesystem, 在macOS上需显式链接boost_filesystem(否则缺符号); MSVC无需。
IF(MSVC)
	SET(FS_LIB "")
ELSEIF(APPLE)
	SET(FS_LIB boost_filesystem)
ELSE()
	SET(FS_LIB stdc++fs)
ENDIF()

# iconv: Windows和macOS需显式链接; Linux的glibc已内置, 无需单独链接。
# macOS下众多模块经WTSUtils等间接使用iconv, 故在此全局链接(对后续所有target生效),
# 避免逐个模块添加。
IF(APPLE)
	SET(ICONV_LIB iconv)
	LINK_LIBRARIES(iconv)
ELSE()
	SET(ICONV_LIB "")
ENDIF()

#basic libraries
ADD_SUBDIRECTORY(WTSUtils)
ADD_SUBDIRECTORY(WTSTools)

#contract Loade through ctp channel
ADD_SUBDIRECTORY(CTPLoader)
ADD_SUBDIRECTORY(CTPOptLoader)
ADD_SUBDIRECTORY(LoaderRunner)

#parser for quote date from ctp channel
ADD_SUBDIRECTORY(ParserCTP)
ADD_SUBDIRECTORY(ParserCTPMini)
ADD_SUBDIRECTORY(ParserCTPOpt)
ADD_SUBDIRECTORY(ParserFemas)
ADD_SUBDIRECTORY(ParserXTP)
ADD_SUBDIRECTORY(ParserShm)
ADD_SUBDIRECTORY(ParserXeleSkt)
ADD_SUBDIRECTORY(WtDataStorage)
ADD_SUBDIRECTORY(WtDataStorageAD)
ADD_SUBDIRECTORY(WtIndexFactory)
ADD_SUBDIRECTORY(WtDtCore)
ADD_SUBDIRECTORY(WtDtHelper)
ADD_SUBDIRECTORY(WtDtPorter)
ADD_SUBDIRECTORY(WtDtServo)
#quote date processor
ADD_SUBDIRECTORY(QuoteFactory)

#back test core library
ADD_SUBDIRECTORY(WtBtCore)
#back test c porter for outter libraries
ADD_SUBDIRECTORY(WtBtPorter)
ADD_SUBDIRECTORY(WtBtRunner)

ADD_SUBDIRECTORY(ParserUDP)
ADD_SUBDIRECTORY(TraderCTP)
ADD_SUBDIRECTORY(TraderCTPMini)
ADD_SUBDIRECTORY(TraderCTPOpt)
ADD_SUBDIRECTORY(TraderFemas)
ADD_SUBDIRECTORY(TraderMocker)
ADD_SUBDIRECTORY(TraderXTP)
ADD_SUBDIRECTORY(TraderYD)
ADD_SUBDIRECTORY(WtExeFact)
ADD_SUBDIRECTORY(WtRiskMonFact)

ADD_SUBDIRECTORY(WtMsgQue)
ADD_SUBDIRECTORY(WtCore)
ADD_SUBDIRECTORY(WtPorter)
ADD_SUBDIRECTORY(WtExecMon)
ADD_SUBDIRECTORY(WtRunner)

ADD_SUBDIRECTORY(TraderDumper)

ADD_SUBDIRECTORY(WtShareHelper)

#uft
ADD_SUBDIRECTORY(WtUftCore)
ADD_SUBDIRECTORY(WtUftStraFact)
ADD_SUBDIRECTORY(WtUftRunner)

ADD_SUBDIRECTORY(WtLatencyHFT)
ADD_SUBDIRECTORY(WtLatencyUFT)

#test projects
ADD_SUBDIRECTORY(TestBtPorter)
ADD_SUBDIRECTORY(TestDtPorter)
ADD_SUBDIRECTORY(TestExecPorter)
ADD_SUBDIRECTORY(TestPorter)
ADD_SUBDIRECTORY(TestTrader)
ADD_SUBDIRECTORY(TestParser)
ADD_SUBDIRECTORY(TestUnits)

