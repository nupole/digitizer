include_guard()

function(copy_file COPY_COMMAND_SOURCE COPY_COMMAND_OUTPUT)
    add_custom_command(OUTPUT ${COPY_COMMAND_OUTPUT}
                       COMMAND ${CMAKE_COMMAND}
                       ARGS -E copy
                            ${COPY_COMMAND_SOURCE}
                            ${COPY_COMMAND_OUTPUT}
                       DEPENDS ${COPY_COMMAND_SOURCE}
                       COMMENT "Copying file ${COPY_COMMAND_SOURCE} to ${COPY_COMMAND_OUTPUT}")
endfunction()
