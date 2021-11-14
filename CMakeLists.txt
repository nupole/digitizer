cmake_minimum_required(VERSION 3.20)

project(digitizer)

cmake_path(SET CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(add_ghdl_target)
include(add_python_target)

add_subdirectory(fw)
