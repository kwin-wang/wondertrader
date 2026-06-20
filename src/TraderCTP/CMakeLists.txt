
#1. 确定CMake的最低版本需求
cmake_minimum_required(VERSION 3.10)

#2. 确定工程名
PROJECT(TraderCTP LANGUAGES CXX)
SET(CMAKE_CXX_STANDARD 17)

SET(SRC  
	${PROJECT_SOURCE_DIR}/TraderCTP.cpp
	${PROJECT_SOURCE_DIR}/TraderCTP.h
)

SET(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/build_${PLATFORM}/${CMAKE_BUILD_TYPE}/bin)

INCLUDE_DIRECTORIES(${INCS})
LINK_DIRECTORIES(${LNKS})
ADD_LIBRARY(TraderCTP SHARED ${SRC})

IF(MSVC)
ELSEIF(APPLE)
	# 使用CTP自带的OpenSSL 1.x静态库(含SSL_get_peer_certificate等旧符号),
	# 避免误链到Homebrew的OpenSSL 3.x; comunicationkeylib.a无lib前缀须用完整路径
	SET(CTP_LIB_DIR ${PROJECT_SOURCE_DIR}/../API/CTP6.6.9/darwin/libs)
	TARGET_LINK_DIRECTORIES(TraderCTP PRIVATE
		${PROJECT_SOURCE_DIR}/../API/CTP6.6.9/darwin
		${CTP_LIB_DIR})
	SET(LIBS
		pthread
		boost_filesystem
		dl
		thosttraderapi_se
		${CTP_LIB_DIR}/libssl.a
		${CTP_LIB_DIR}/libcrypto.a
		${CTP_LIB_DIR}/comunicationkeylib.a
	)
	TARGET_LINK_LIBRARIES(TraderCTP ${LIBS})
ELSE(GNUCC)
	SET(LIBS
		pthread
		${FS_LIB}
        boost_filesystem
		dl
	)
	TARGET_LINK_LIBRARIES(TraderCTP ${LIBS})
ENDIF()

IF (MSVC)
ELSE (GNUCC)
	SET_TARGET_PROPERTIES(TraderCTP PROPERTIES
		CXX_VISIBILITY_PRESET hidden
		C_VISIBILITY_PRESET hidden
		VISIBILITY_INLINES_HIDDEN 1
        LINK_FLAGS_RELEASE -s)
ENDIF ()

