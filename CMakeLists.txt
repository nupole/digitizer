cmake_minimum_required(VERSION 3.13.4)

project(digitizer)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(AddGHDLTarget)

add_subdirectory(fw)
