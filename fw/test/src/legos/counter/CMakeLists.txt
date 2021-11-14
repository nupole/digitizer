add_ghdl_target(hdl_counter_tb HDL_SOURCE counter_tb.vhdl
                               COCOTB_MODULE counter_tb.py
                               HDL_DEPENDS hdl_counter
                               COCOTB_MODULE_DEPENDS python_counter)
