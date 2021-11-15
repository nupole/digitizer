add_ghdl_target(hdl_sync_fifo HDL_SOURCE sync_fifo.vhdl
                              HDL_DEPENDS hdl_counter
                                          hdl_dual_port_ram)
