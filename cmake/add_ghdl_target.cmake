include_guard()

function(add_ghdl_target GHDL_TARGET_NAME)
    set(one_value_keywords HDL_PACKAGE
                           HDL_SOURCE
                           COCOTB_MODULE)

    set(multi_value_keywords HDL_DEPENDS
                             COCOTB_MODULE_DEPENDS)

    cmake_parse_arguments(ARG "" "${one_value_keywords}" "${multi_value_keywords}" ${ARGN})

    if(NOT (DEFINED ARG_HDL_PACKAGE OR DEFINED ARG_HDL_SOURCE))
        message(FATAL_ERROR "No HDL package or HDL source...")
    endif()

    if(DEFINED ARG_HDL_PACKAGE)
        cmake_path(SET GHDL_COMPILE_COMMAND_HDL_PACKAGE ${CMAKE_CURRENT_SOURCE_DIR}/${ARG_HDL_PACKAGE})
        if(NOT EXISTS ${GHDL_COMPILE_COMMAND_HDL_PACKAGE})
            message(FATAL_ERROR "HDL package doesn't exist: ${GHDL_COMPILE_COMMAND_HDL_PACKAGE}")
        endif()
        cmake_path(GET GHDL_COMPILE_COMMAND_HDL_PACKAGE STEM GHDL_COMPILE_COMMAND_HDL_PACKAGE_FILENAME_WITHOUT_EXTENSION)
        list(APPEND GHDL_COMPILE_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${GHDL_COMPILE_COMMAND_HDL_PACKAGE_FILENAME_WITHOUT_EXTENSION}.o)
    endif()

    if(DEFINED ARG_HDL_SOURCE)
        cmake_path(SET GHDL_COMPILE_COMMAND_HDL_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/${ARG_HDL_SOURCE})
        if(NOT EXISTS ${GHDL_COMPILE_COMMAND_HDL_SOURCE})
            message(FATAL_ERROR "HDL source doesn't exist: ${GHDL_COMPILE_COMMAND_HDL_SOURCE}")
        endif()
        cmake_path(GET GHDL_COMPILE_COMMAND_HDL_SOURCE STEM GHDL_COMPILE_COMMAND_HDL_SOURCE_FILENAME_WITHOUT_EXTENSION)
        list(APPEND GHDL_COMPILE_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${GHDL_COMPILE_COMMAND_HDL_SOURCE_FILENAME_WITHOUT_EXTENSION}.o)
    endif()

    list(APPEND GHDL_COMPILE_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${GHDL_TARGET_NAME}-obj08.cf)

    foreach(GHDL_TARGET_DEPEND ${ARG_HDL_DEPENDS})
        get_target_property(GHDL_TARGET_DEPEND_OUTPUT ${GHDL_TARGET_DEPEND} OUTPUT)
        get_target_property(GHDL_TARGET_DEPEND_INCLUDE_DIRECTORIES ${GHDL_TARGET_DEPEND} INCLUDE_DIRECTORIES)
        list(APPEND GHDL_TARGET_DEPENDS_OUTPUT ${GHDL_TARGET_DEPEND_OUTPUT})
        list(APPEND GHDL_TARGET_DEPENDS_INCLUDE_DIRECTORIES ${GHDL_TARGET_DEPEND_INCLUDE_DIRECTORIES})
    endforeach()

    add_custom_command(OUTPUT ${GHDL_COMPILE_COMMAND_OUTPUT}
                       COMMAND ghdl
                       ARGS -a
                            --std=08
                            --work=${GHDL_TARGET_NAME}
                            ${GHDL_TARGET_DEPENDS_INCLUDE_DIRECTORIES}
                            ${GHDL_COMPILE_COMMAND_HDL_PACKAGE}
                            ${GHDL_COMPILE_COMMAND_HDL_SOURCE}
                       DEPENDS ${GHDL_TARGET_DEPENDS_OUTPUT}
                               ${GHDL_COMPILE_COMMAND_HDL_PACKAGE}
                               ${GHDL_COMPILE_COMMAND_HDL_SOURCE}
                       COMMENT "Compiling GHDL target ${GHDL_TARGET_NAME}")

    set(GHDL_TARGET_OUTPUT ${GHDL_COMPILE_COMMAND_OUTPUT})

    if(DEFINED ARG_COCOTB_MODULE)
        set(GHDL_ELABORATE_COMMAND_UNIT ${GHDL_COMPILE_COMMAND_HDL_SOURCE_FILENAME_WITHOUT_EXTENSION})
        cmake_path(SET GHDL_ELABORATE_COMMAND_OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/test_${GHDL_ELABORATE_COMMAND_UNIT})
        list(APPEND GHDL_ELABORATE_COMMAND_OUTPUT ${GHDL_ELABORATE_COMMAND_OUTPUT_FILE})
        list(APPEND GHDL_ELABORATE_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/e~test_${GHDL_ELABORATE_COMMAND_UNIT}.o)
        set(GHDL_ELABORATE_COMMAND_DEPENDS ${GHDL_COMPILE_COMMAND_OUTPUT})

        add_custom_command(OUTPUT ${GHDL_ELABORATE_COMMAND_OUTPUT}
                           COMMAND ghdl
                           ARGS -e
                                --std=08
                                --work=${GHDL_TARGET_NAME}
                                ${GHDL_TARGET_DEPENDS_INCLUDE_DIRECTORIES}
                                -o ${GHDL_ELABORATE_COMMAND_OUTPUT_FILE}
                                ${GHDL_ELABORATE_COMMAND_UNIT}
                           DEPENDS ${GHDL_ELABORATE_COMMAND_DEPENDS}
                           COMMENT "Elaborating GHDL Target ${GHDL_TARGET_NAME}")

        cmake_path(SET COCOTB_MODULE_TARGET_SOURCE ${ARG_COCOTB_MODULE})
        cmake_path(GET COCOTB_MODULE_TARGET_SOURCE STEM COCOTB_MODULE_TARGET_SOURCE_FILENAME_WITHOUT_EXTENSION)
        set(COCOTB_MODULE_TARGET_NAME python_${COCOTB_MODULE_TARGET_SOURCE_FILENAME_WITHOUT_EXTENSION})
        set(COCOTB_MODULE_TARGET_DEPENDS ${ARG_COCOTB_MODULE_DEPENDS})

        add_python_target(${COCOTB_MODULE_TARGET_NAME} SOURCE ${COCOTB_MODULE_TARGET_SOURCE}
                                                       DEPENDS ${COCOTB_MODULE_TARGET_DEPENDS})

        set(GHDL_RUN_COMMAND_UNIT test_${GHDL_ELABORATE_COMMAND_UNIT})
        cmake_path(SET GHDL_RUN_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/results.xml)
        get_target_property(GHDL_RUN_COMMAND_DEPENDS ${COCOTB_MODULE_TARGET_NAME} OUTPUT)
        list(APPEND GHDL_RUN_COMMAND_DEPENDS ${GHDL_ELABORATE_COMMAND_OUTPUT})

        execute_process(COMMAND cocotb-config --lib-name-path vpi ghdl OUTPUT_VARIABLE GHDL_RUN_COMMAND_VPI)

        add_custom_command(OUTPUT ${GHDL_RUN_COMMAND_OUTPUT}
                           COMMAND PYTHONPATH=${TESTBENCH_PYTHON_LIBRARY_DIR} MODULE=${COCOTB_MODULE_TARGET_SOURCE_FILENAME_WITHOUT_EXTENSION} ghdl
                           ARGS -r
                                --std=08
                                --work=${GHDL_TARGET_NAME}
                                ${GHDL_TARGET_DEPENDS_INCLUDE_DIRECTORIES}
                                ${GHDL_RUN_COMMAND_UNIT}
                                --vpi=${GHDL_RUN_COMMAND_VPI}
                           DEPENDS ${GHDL_RUN_COMMAND_DEPENDS}
                           COMMENT "Running GHDL Target ${GHDL_TARGET_NAME}")

        cmake_path(SET GHDL_RUN_TRACE_COMMAND_OUTPUT_RESULTS_FILE ${CMAKE_CURRENT_BINARY_DIR}/results_trace.xml)
        cmake_path(SET GHDL_RUN_TRACE_COMMAND_OUTPUT_TRACE_FILE ${CMAKE_CURRENT_BINARY_DIR}/trace.fst)
        list(APPEND GHDL_RUN_TRACE_COMMAND_OUTPUT ${GHDL_RUN_TRACE_COMMAND_OUTPUT_RESULTS_FILE})
        list(APPEND GHDL_RUN_TRACE_COMMAND_OUTPUT ${GHDL_RUN_TRACE_COMMAND_OUTPUT_TRACE_FILE})

        set(GHDL_TRACE_TARGET_NAME ${GHDL_TARGET_NAME}_trace)

        add_custom_command(OUTPUT ${GHDL_RUN_TRACE_COMMAND_OUTPUT}
                           COMMAND PYTHONPATH=${TESTBENCH_PYTHON_LIBRARY_DIR} MODULE=${COCOTB_MODULE_TARGET_SOURCE_FILENAME_WITHOUT_EXTENSION} COCOTB_RESULTS_FILE=${GHDL_RUN_TRACE_COMMAND_OUTPUT_RESULTS_FILE} ghdl
                           ARGS -r
                                --std=08
                                --work=${GHDL_TARGET_NAME}
                                ${GHDL_TARGET_DEPENDS_INCLUDE_DIRECTORIES}
                                ${GHDL_RUN_COMMAND_UNIT}
                                --fst=${GHDL_RUN_TRACE_COMMAND_OUTPUT_TRACE_FILE}
                                --vpi=${GHDL_RUN_COMMAND_VPI}
                           DEPENDS ${GHDL_RUN_COMMAND_DEPENDS}
                           COMMENT "Running GHDL target ${GHDL_TRACE_TARGET_NAME}")

        set(GHDL_TRACE_TARGET_OUTPUT ${GHDL_RUN_TRACE_COMMAND_OUTPUT})
        set(GHDL_TRACE_TARGET_DEPENDS ${ARG_HDL_DEPENDS})

        add_custom_target(${GHDL_TRACE_TARGET_NAME} DEPENDS ${GHDL_TRACE_TARGET_OUTPUT})

        if(DEFINED GHDL_TRACE_TARGET_DEPENDS)
            add_dependencies(${GHDL_TRACE_TARGET_NAME} ${GHDL_TRACE_TARGET_DEPENDS})
        endif()

        set(GHDL_TARGET_OUTPUT ${GHDL_RUN_COMMAND_OUTPUT})
    endif()

    set(GHDL_TARGET_DEPENDS ${ARG_HDL_DEPENDS})

    add_custom_target(${GHDL_TARGET_NAME} ALL
                                          DEPENDS ${GHDL_TARGET_OUTPUT})

    if(DEFINED GHDL_TARGET_DEPENDS)
        add_dependencies(${GHDL_TARGET_NAME} ${GHDL_TARGET_DEPENDS})
    endif()

    list(APPEND GHDL_TARGET_INCLUDE_DIRECTORIES ${GHDL_TARGET_DEPENDS_INCLUDE_DIRECTORIES})
    list(APPEND GHDL_TARGET_INCLUDE_DIRECTORIES -P${CMAKE_CURRENT_BINARY_DIR})

    set_target_properties(${GHDL_TARGET_NAME} PROPERTIES INCLUDE_DIRECTORIES "${GHDL_TARGET_INCLUDE_DIRECTORIES}"
                                                         OUTPUT "${GHDL_TARGET_OUTPUT}")
endfunction()
