cmake_minimum_required(VERSION 3.2)
project(fzf LANGUAGES CXX C)

add_library(${PROJECT_NAME} SHARED "src/fzf.c" )

target_include_directories(${PROJECT_NAME} PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>)
target_compile_options(${PROJECT_NAME}
  PRIVATE
    $<$<C_COMPILER_ID:MSVC>:/W4>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wall>)
target_compile_definitions(${PROJECT_NAME}
  PRIVATE
    $<$<PLATFORM_ID:Windows>:_CRT_NONSTDC_NO_DEPRECATE>
    $<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_DEPRECATE>
    $<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_WARNINGS>)

set_target_properties(${PROJECT_NAME} PROPERTIES
    WINDOWS_EXPORT_ALL_SYMBOLS ON
    C_STANDARD 99
    PREFIX lib)

# This cannot be a generator expression in this version of CMake
if (NOT (MSVC OR MSYS OR MINGW OR WIN32))
  set_property(TARGET ${PROJECT_NAME} PROPERTY SUFFIX .so)
endif()

install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_BINARY_DIR})

# New shared library for frecency.cpp
add_library(frecency SHARED "src/frecency.cpp")

target_include_directories(frecency PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>)
target_compile_options(frecency
  PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall>)
target_compile_definitions(frecency
  PRIVATE
    $<$<PLATFORM_ID:Windows>:_CRT_NONSTDC_NO_DEPRECATE>
    $<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_DEPRECATE>
    $<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_WARNINGS>)

set_target_properties(frecency PROPERTIES
    WINDOWS_EXPORT_ALL_SYMBOLS ON
    CXX_STANDARD 17
    PREFIX lib)

# Apply suffix for non-Windows platforms if desired (similar to fzf)
if (NOT (MSVC OR MSYS OR MINGW OR WIN32))
  set_property(TARGET frecency PROPERTY SUFFIX .so)
endif()

# Install the new frecency library
install(TARGETS frecency DESTINATION ${CMAKE_BINARY_DIR})
