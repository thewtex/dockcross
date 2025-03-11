set(WASI_SDK_PREFIX $ENV{WASI_SDK_PATH})
include($ENV{WASI_SDK_PATH}/share/cmake/wasi-sdk-pthread.cmake)

list(APPEND CMAKE_FIND_ROOT_PATH ${CMAKE_PREFIX_PATH} $ENV{CROSS_ROOT})
set(CMAKE_SYSROOT $ENV{WASI_SYSROOT})

set(CMAKE_C_COMPILER /usr/local/bin/clang-wasi-threads-sysroot.sh)
set(CMAKE_CXX_COMPILER /usr/local/bin/clang++-wasi-threads-sysroot.sh)

set(CMAKE_CROSSCOMPILING_EMULATOR /wasi-runtimes/wasmtime/bin/wasmtime-pwd-threads.sh)
