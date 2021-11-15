add_python_target(python_sync_fifo SOURCE __init__.py
                                   DEPENDS python_counter
                                           python_dual_port_ram)
