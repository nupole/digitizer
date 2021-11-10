include_guard()

function(add_ghdl_target ghdl_target_name)
    set(one_value_keywords INCLUDE
                           SOURCE)

    cmake_parse_arguments(GHDL_TARGET "" "${one_value_keywords}" "" ${ARGN})

    if(DEFINED GHDL_TARGET_INCLUDE)
        get_filename_component(GHDL_TARGET_INCLUDE_FILE ${GHDL_TARGET_INCLUDE} REALPATH)
        if(NOT EXISTS ${GHDL_TARGET_INCLUDE_FILE})
            message(FATAL_ERROR "File doesn't exist: ${GHDL_TARGET_INCLUDE}")
        endif()
        get_filename_component(GHDL_TARGET_INCLUDE_FILE_NAME ${GHDL_TARGET_INCLUDE} NAME_WE)
        list(APPEND GHDL_TARGET_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${GHDL_TARGET_INCLUDE_FILE_NAME}.o)
    endif()

    if(DEFINED GHDL_TARGET_SOURCE)
        get_filename_component(GHDL_TARGET_SOURCE_FILE ${GHDL_TARGET_SOURCE} REALPATH)
        if(NOT EXISTS ${GHDL_TARGET_SOURCE_FILE})
            message(FATAL_ERROR "File doesn't exist: ${GHDL_TARGET_SOURCE}")
        endif()
        get_filename_component(GHDL_TARGET_SOURCE_FILE_NAME ${GHDL_TARGET_SOURCE} NAME_WE)
        list(APPEND GHDL_TARGET_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${GHDL_TARGET_SOURCE_FILE_NAME}.o)
    endif()

    list(APPEND GHDL_TARGET_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ghdl_target_name}-obj08.cf)

    add_custom_command(OUTPUT ${GHDL_TARGET_OUTPUT}
                       COMMAND ghdl
                       ARGS -a
                            --std=08
                            --work=${ghdl_target_name}
                            ${GHDL_TARGET_INCLUDE_FILE}
                            ${GHDL_TARGET_SOURCE_FILE}
                       DEPENDS ${GHDL_TARGET_INCLUDE_FILE}
                               ${GHDL_TARGET_SOURCE_FILE}
                       COMMENT "Compiling GHDL Target ${ghdl_target_name}")

    add_custom_target(${ghdl_target_name} ALL
                                          DEPENDS ${GHDL_TARGET_OUTPUT})
endfunction()
