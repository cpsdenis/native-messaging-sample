cmake_minimum_required(VERSION 3.12)
project(NativeMessagingSampleHost CXX)
set(CMAKE_CXX_STANDARD 17)

if(WIN32 AND CMAKE_COMPILER_IS_GNUCXX)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -static-libgcc -static-libstdc++")
endif()

add_subdirectory(host/src)