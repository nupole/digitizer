add_ghdl_target(hdl_sync_fifo_tb HDL_SOURCE sync_fifo_tb.vhdl
                                 COCOTB_MODULE sync_fifo_tb.py
                                 HDL_DEPENDS hdl_sync_fifo
                                 COCOTB_MODULE_DEPENDS python_sync_fifo)
