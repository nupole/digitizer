add_ghdl_target(hdl_dual_port_ram_tb HDL_SOURCE dual_port_ram_tb.vhdl
                                     COCOTB_MODULE dual_port_ram_tb.py
                                     HDL_DEPENDS hdl_dual_port_ram
                                     COCOTB_MODULE_DEPENDS python_dual_port_ram)
