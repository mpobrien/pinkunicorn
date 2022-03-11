cmake_minimum_required(VERSION 3.15)

project(pink_unicorn)

# Project-wide build flags
set(CMAKE_CXX_STANDARD 20)

add_subdirectory(realm-core)

set(REALM_INCLUDE_CERTS 0)
set(REALM_NO_CONFIG)
set(REALM_ENABLE_SYNC)
set(REALM_NO_TESTS)
set(REALM_BUILD_LIB_ONLY)
set(REALM_INSTALL_LIBEXECDIR)
set(REALM_ENABLE_ENCRYPTION 1)

add_compile_definitions(REALM_NO_CONFIG)
add_compile_definitions(REALM_ENABLE_SYNC)
add_compile_definitions(REALM_ENABLE_ENCRYPTION)
add_compile_definitions(REALM_INSTALL_LIBEXECDIR)
add_compile_definitions(REALM_BUILD_LIB_ONLY)
add_compile_definitions(REALM_VERSION_MAJOR=0)
add_compile_definitions(REALM_VERSION_MINOR=0)
add_compile_definitions(REALM_VERSION_PATCH=1)

set(SOURCES
    pink_unicorn.cpp
) 

set(HEADERS)

add_executable(pink_unicorn pink_unicorn.cpp)
target_include_directories(pink_unicorn PRIVATE realm-core/src)
target_include_directories(pink_unicorn PUBLIC .)
set_property(TARGET pink_unicorn PROPERTY CXX_STANDARD 20)
set_property(TARGET pink_unicorn PROPERTY CXX_STANDARD 20)
target_compile_options(pink_unicorn PUBLIC -std=c++2a)
target_link_libraries(pink_unicorn Storage ObjectStore Sync z curl)
