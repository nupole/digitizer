include_guard()

include(utility)

function(add_python_target PYTHON_TARGET_NAME)
    set(one_value_keywords SOURCE)

    set(multi_value_keywords DEPENDS)

    cmake_parse_arguments(ARG "" "${one_value_keywords}" "${multi_value_keywords}" ${ARGN})

    if(NOT DEFINED ARG_SOURCE)
        message(FATAL_ERROR "No python source...")
    endif()

    cmake_path(SET COPY_COMMAND_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/${ARG_SOURCE})
    cmake_path(GET COPY_COMMAND_SOURCE FILENAME COPY_COMMAND_SOURCE_FILENAME)
    cmake_path(SET COPY_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${COPY_COMMAND_SOURCE_FILENAME})

    copy_file(${COPY_COMMAND_SOURCE} ${COPY_COMMAND_OUTPUT})

    cmake_path(SET PYTHON_COMPILE_COMMAND_SOURCE ${COPY_COMMAND_OUTPUT})
    cmake_path(GET PYTHON_COMPILE_COMMAND_SOURCE STEM PYTHON_COMPILE_COMMAND_SOURCE_FILENAME_WITHOUT_EXTENSION)
    cmake_path(SET PYTHON_COMPILE_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/__pycache__/${PYTHON_COMPILE_COMMAND_SOURCE_FILENAME_WITHOUT_EXTENSION}.cpython-39.pyc)

    foreach(PYTHON_TARGET_DEPEND ${ARG_DEPENDS})
        get_target_property(PYTHON_TARGET_DEPEND_OUTPUT ${PYTHON_TARGET_DEPEND} OUTPUT)
        list(APPEND PYTHON_TARGET_DEPENDS_OUTPUT ${PYTHON_TARGET_DEPEND_OUTPUT})
    endforeach()

    add_custom_command(OUTPUT ${PYTHON_COMPILE_COMMAND_OUTPUT}
                       COMMAND python3
                       ARGS -m py_compile
                            ${PYTHON_COMPILE_COMMAND_SOURCE}
                       DEPENDS ${PYTHON_TARGET_DEPENDS_OUTPUT}
                               ${PYTHON_COMPILE_COMMAND_SOURCE}
                       COMMENT "Compiling Python target ${PYTHON_TARGET_NAME}")

    set(PYTHON_TARGET_OUTPUT ${PYTHON_COMPILE_COMMAND_OUTPUT})
    set(PYTHON_TARGET_DEPENDS ${ARG_DEPENDS})

    add_custom_target(${PYTHON_TARGET_NAME} ALL
                                            DEPENDS ${PYTHON_TARGET_DEPENDS_OUTPUT}
                                                    ${PYTHON_TARGET_OUTPUT})

    if(DEFINED PYTHON_TARGET_DEPENDS)
        add_dependencies(${PYTHON_TARGET_NAME} ${PYTHON_TARGET_DEPENDS})
    endif()

    set_target_properties(${PYTHON_TARGET_NAME} PROPERTIES OUTPUT "${PYTHON_TARGET_OUTPUT}")
endfunction()
